import Foundation

@MainActor
@Observable
final class RewardsViewModel {
    enum Section: String, CaseIterable, Identifiable {
        case rewards, redeems, archive

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .rewards: "Награды"
            case .redeems: "Дневник"
            case .archive: "Архив"
            }
        }
    }

    private(set) var rewards: [Reward] = []
    private(set) var archivedRewards: [Reward] = []
    private(set) var redeems: [Redeem] = []
    private(set) var walletBalance: Int = 0
    private(set) var isLoading = false
    var section: Section = .rewards
    var errorMessage: String?
    /// Redeem/archive failures surface as an alert instead of a line at the
    /// bottom of the list, where they were easy to miss.
    var actionErrorMessage: String?
    /// Set after a successful redeem; drives the full-screen celebration.
    var celebration: RedeemCelebration?

    var spentTotal: Int {
        redeems.reduce(0) { $0 + $1.amountSpent }
    }

    func load(apiClient: APIClient) async {
        isLoading = true
        errorMessage = nil
        do {
            async let rewardsTask: [Reward] = apiClient.get("/rewards")
            async let archivedTask: [Reward] = apiClient.get("/rewards?archived=true")
            async let redeemsTask: [Redeem] = apiClient.get("/redeems")
            async let balanceTask: WalletBalance = apiClient.get("/wallet/balance")
            let (fetchedRewards, fetchedArchived, fetchedRedeems, balance) =
                try await (rewardsTask, archivedTask, redeemsTask, balanceTask)
            rewards = fetchedRewards
            archivedRewards = fetchedArchived
            redeems = fetchedRedeems
            walletBalance = balance.balance
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // Spending changes the wallet balance and adds a redeem, so reload rather
    // than mutate locally — keeps the header balance and the spend log correct.
    func redeem(_ reward: Reward, apiClient: APIClient) async {
        actionErrorMessage = nil
        do {
            let redeem: Redeem = try await apiClient.post("/redeems", body: CreateRedeemRequest(rewardId: reward.id))
            await load(apiClient: apiClient)
            celebration = RedeemCelebration(redeem: redeem, rewardName: reward.name, isFirst: redeems.count == 1)
            await NotificationScheduler.schedulePhotoReminder(rewardName: reward.name)
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    func archive(_ reward: Reward, apiClient: APIClient) async {
        actionErrorMessage = nil
        do {
            let archived: Reward = try await apiClient.patch("/rewards/\(reward.id)")
            rewards.removeAll { $0.id == reward.id }
            archivedRewards.insert(archived, at: 0)
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    /// Starring a reward makes it the goal shown in the Habits header; the
    /// backend unstars any other. Tapping the current goal unstars it.
    func toggleGoal(_ reward: Reward, apiClient: APIClient) async {
        actionErrorMessage = nil
        do {
            if reward.isGoal == true {
                try await apiClient.delete("/rewards/\(reward.id)/goal")
            } else {
                try await apiClient.put("/rewards/\(reward.id)/goal")
            }
            rewards = try await apiClient.get("/rewards")
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    func restore(_ reward: Reward, apiClient: APIClient) async {
        actionErrorMessage = nil
        do {
            let restored: Reward = try await apiClient.patch("/rewards/\(reward.id)/restore")
            archivedRewards.removeAll { $0.id == reward.id }
            rewards.insert(restored, at: 0)
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }
}
