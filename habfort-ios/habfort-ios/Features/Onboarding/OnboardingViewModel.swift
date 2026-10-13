import Foundation

struct RewardTemplate: Identifiable, Hashable {
    let name: String
    let icon: String
    let costCoins: Int
    var id: String { name }

    static let all: [RewardTemplate] = [
        RewardTemplate(name: "Кофе в любимом месте", icon: "cup.and.saucer.fill", costCoins: 100),
        RewardTemplate(name: "Десерт", icon: "birthday.cake.fill", costCoins: 100),
        RewardTemplate(name: "Поход в кино", icon: "film.fill", costCoins: 120),
        RewardTemplate(name: "Новая книга", icon: "book.fill", costCoins: 150),
    ]
}

@MainActor
@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable { case welcome, goal, howItWorks }

    var step: Step = .welcome
    var selectedTemplate: RewardTemplate? = RewardTemplate.all.first
    var isCustom = false
    var customName = ""
    var customCostText = "" {
        didSet {
            let filtered = customCostText.filter(\.isNumber)
            if filtered != customCostText { customCostText = filtered }
        }
    }
    private(set) var economy: EconomyConfig?
    private(set) var isSubmitting = false
    var errorMessage: String?
    /// Kept across retries so a failure after the reward was created doesn't
    /// create it a second time.
    private var createdRewardId: String?

    /// Above this a first goal is likely too far away to keep someone going;
    /// it's a warning, never a limit — reward prices have no maximum.
    static let bigFirstGoalCoins = 300

    var welcomeBonus: Int { economy?.welcomeBonus ?? 60 }
    var minCost: Int { economy?.rewardMinCostCoins ?? 100 }

    var goalName: String {
        isCustom ? customName.trimmingCharacters(in: .whitespacesAndNewlines) : (selectedTemplate?.name ?? "")
    }

    var goalCost: Int? {
        isCustom ? Int(customCostText) : selectedTemplate?.costCoins
    }

    var isGoalValid: Bool {
        guard let goalCost else { return false }
        return !goalName.isEmpty && goalCost >= minCost
    }

    var isGoalTooBig: Bool {
        (goalCost ?? 0) > Self.bigFirstGoalCoins
    }

    var coinsLeftAfterBonus: Int {
        max(0, (goalCost ?? 0) - welcomeBonus)
    }

    /// Days to the goal with one medium habit a day — the yardstick the
    /// onboarding promises ("about 3 days").
    var daysToGoal: Int {
        let perDay = economy?.coins(for: .medium) ?? 10
        return Int((Double(coinsLeftAfterBonus) / Double(max(perDay, 1))).rounded(.up))
    }

    func loadEconomy(apiClient: APIClient) async {
        guard economy == nil else { return }
        economy = try? await apiClient.get("/economy")
    }

    /// Creates the first reward as the starred goal, then completes onboarding
    /// (which credits the welcome bonus).
    func finish(apiClient: APIClient) async -> Bool {
        guard let goalCost, isGoalValid else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            if createdRewardId == nil {
                let reward: Reward = try await apiClient.post(
                    "/rewards", body: CreateRewardRequest(name: goalName, costCoins: goalCost)
                )
                createdRewardId = reward.id
            }
            if let createdRewardId {
                try await apiClient.put("/rewards/\(createdRewardId)/goal")
            }
            let _: Me = try await apiClient.post("/me/onboarding")
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
