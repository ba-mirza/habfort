import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var walletBalance: Int = 0
    private(set) var discipline: DisciplineStats?
    private(set) var habits: [Habit] = []
    private(set) var rewards: [Reward] = []
    private(set) var isLoading = false
    var errorMessage: String?

    /// The longest streak currently running, across challenges and recurring
    /// habits.
    var bestStreak: Int {
        habits.compactMap(\.currentStreak).max() ?? 0
    }

    /// Same "due today" rule as the Habits tab, so the two screens can't
    /// disagree about whether the day is closed.
    var todaysHabits: [Habit] {
        habits.filter(\.isScheduledToday)
    }

    var isTodayClosed: Bool {
        !todaysHabits.isEmpty && todaysHabits.allSatisfy { $0.isCompletedToday == true }
    }

    /// The cheapest active reward is the one the balance is working towards.
    var nextReward: Reward? {
        rewards.min { $0.costCoins < $1.costCoins }
    }

    var rewardProgress: Double? {
        guard let nextReward, nextReward.costCoins > 0 else { return nil }
        return min(1, Double(walletBalance) / Double(nextReward.costCoins))
    }

    /// Active habits per type, for the composition bar. Types with no habits
    /// are dropped so the bar has no zero-width segments.
    var habitCountsByType: [(type: HabitType, count: Int)] {
        HabitType.allCases
            .map { type in (type: type, count: habits.filter { $0.type == type }.count) }
            .filter { $0.count > 0 }
    }

    func load(apiClient: APIClient) async {
        isLoading = true
        errorMessage = nil
        do {
            async let balanceTask: WalletBalance = apiClient.get("/wallet/balance")
            async let disciplineTask: DisciplineStats = apiClient.get("/history/discipline")
            async let habitsTask: [Habit] = apiClient.get("/habits")
            async let rewardsTask: [Reward] = apiClient.get("/rewards")
            let (balance, fetchedDiscipline, fetchedHabits, fetchedRewards) =
                try await (balanceTask, disciplineTask, habitsTask, rewardsTask)
            walletBalance = balance.balance
            discipline = fetchedDiscipline
            habits = fetchedHabits
            rewards = fetchedRewards
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
