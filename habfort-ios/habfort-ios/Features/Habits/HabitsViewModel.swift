import SwiftUI

@MainActor
@Observable
final class HabitsViewModel {
    private(set) var habits: [Habit] = []
    private(set) var walletBalance: Int = 0
    private(set) var goal: Reward?
    private(set) var streak: DayStreak?
    private(set) var economy: EconomyConfig?
    /// This week's closed entries, for the day strip's past days.
    private(set) var weekHistory: [HabitHistoryEntry] = []
    private(set) var isLoading = false
    var errorMessage: String?
    /// In-app moment when a completion carries the balance past 80% of the
    /// goal or to the goal itself.
    var milestone: GoalMilestone?

    private var goalProgress: Double {
        guard let goal, goal.costCoins > 0 else { return 0 }
        return Double(walletBalance) / Double(goal.costCoins)
    }

    // INSTANT/CONDITIONAL have no per-day schedule so they're always "today";
    // RECURRING only counts on its scheduled days.
    var todaysHabits: [Habit] {
        habits.filter { $0.isScheduledToday }
    }

    func load(apiClient: APIClient) async {
        isLoading = true
        errorMessage = nil
        do {
            async let habitsTask: [Habit] = apiClient.get("/habits")
            async let balanceTask: WalletBalance = apiClient.get("/wallet/balance")
            async let weekTask: [HabitHistoryEntry] = apiClient.get(Self.weekHistoryPath())
            async let rewardsTask: [Reward] = apiClient.get("/rewards")
            async let streakTask: DayStreak = apiClient.get("/history/streak")
            let (fetchedHabits, balance, week, rewards, fetchedStreak) =
                try await (habitsTask, balanceTask, weekTask, rewardsTask, streakTask)
            streak = fetchedStreak
            if economy == nil {
                economy = try? await apiClient.get("/economy")
            }
            goal = rewards.goal
            weekHistory = week
            // Animated so a habit that closed out server-side slides away.
            withAnimation { habits = fetchedHabits }
            walletBalance = balance.balance
            await NotificationScheduler.rescheduleDormantReminder(goal: goal, balance: walletBalance)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private(set) var pendingIds: Set<String> = []

    /// Checkbox tap. The check appears at once; the request and a reload run
    /// behind it, since INSTANT/CONDITIONAL can close out server-side (archived
    /// to history and gone from the list) and the balance changes. A failure
    /// clears the optimistic check.
    func toggleCompletion(_ habit: Habit, apiClient: APIClient) async {
        guard !pendingIds.contains(habit.id),
              let index = habits.firstIndex(where: { $0.id == habit.id })
        else { return }
        let completed = !(habit.isCompletedToday ?? false)
        pendingIds.insert(habit.id)
        defer { pendingIds.remove(habit.id) }
        errorMessage = nil
        habits[index].isCompletedToday = completed

        do {
            if habit.type == .instant {
                try await apiClient.post("/habits/\(habit.id)/complete")
            } else {
                try await apiClient.post("/habits/\(habit.id)/log", body: LogHabitDayRequest(completed: completed))
            }
            let goalBefore = goal?.id
            let progressBefore = goalProgress
            await load(apiClient: apiClient)
            if completed {
                if let goal, goal.id == goalBefore {
                    milestone = GoalMilestone(crossing: progressBefore, to: goalProgress, goal: goal, balance: walletBalance)
                        ?? milestone
                }
                await NotificationScheduler.requestPermissionAfterFirstCompletion()
            }
        } catch {
            if let index = habits.firstIndex(where: { $0.id == habit.id }) {
                habits[index].isCompletedToday = habit.isCompletedToday
            }
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ habit: Habit, apiClient: APIClient) async {
        // Optimistic: the row disappears with the swipe, the request runs
        // behind it, and only a failure puts the habit back where it was.
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        errorMessage = nil
        _ = withAnimation { habits.remove(at: index) }
        do {
            try await apiClient.delete("/habits/\(habit.id)")
        } catch {
            withAnimation { habits.insert(habit, at: min(index, habits.count)) }
            errorMessage = error.localizedDescription
        }
    }

    /// Swaps in an edited habit. PATCH returns the bare row, so the read-time
    /// fields (streak, today's completion) carry over from the current copy.
    func replace(_ updated: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == updated.id }) else { return }
        var merged = updated
        merged.currentStreak = habits[index].currentStreak
        merged.isCompletedToday = habits[index].isCompletedToday
        habits[index] = merged
    }

    /// What completing the habit pays, for the card's reward column.
    func reward(for habit: Habit) -> (coins: Int, xp: Int)? {
        guard let economy, let coins = economy.coins(for: habit.difficulty) else { return nil }
        return (coins, coins * economy.xpPerCoin)
    }

    var todaysDoneCount: Int {
        todaysHabits.filter { $0.isCompletedToday == true }.count
    }

    private static func weekHistoryPath() -> String {
        let days = WeekCalendar.days()
        guard let first = days.first, let last = days.last,
              let end = WeekCalendar.calendar.date(byAdding: .day, value: 1, to: last)
        else { return "/history?take=100" }
        let formatter = ISO8601DateFormatter()
        return "/history?take=100&from=\(formatter.string(from: first))&to=\(formatter.string(from: end))"
    }
}

struct GoalMilestone: Identifiable, Equatable {
    enum Kind { case almostThere, reached }

    let id = UUID()
    let kind: Kind
    let goalName: String
    let coinsLeft: Int

    /// Share of the goal where the header bar "speeds up" and the user hears
    /// they're nearly there.
    static let almostThereShare = 0.8

    /// Nil unless this step crossed a threshold — staying above it isn't news.
    init?(crossing before: Double, to after: Double, goal: Reward, balance: Int) {
        if before < 1, after >= 1 {
            kind = .reached
        } else if before < Self.almostThereShare, after >= Self.almostThereShare, after < 1 {
            kind = .almostThere
        } else {
            return nil
        }
        goalName = goal.name
        coinsLeft = max(0, goal.costCoins - balance)
    }
}
