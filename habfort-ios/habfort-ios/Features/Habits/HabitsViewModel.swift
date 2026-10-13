import SwiftUI

@MainActor
@Observable
final class HabitsViewModel {
    private(set) var habits: [Habit] = []
    private(set) var walletBalance: Int = 0
    private(set) var isLoading = false
    var errorMessage: String?

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
            let (fetchedHabits, balance) = try await (habitsTask, balanceTask)
            habits = fetchedHabits
            walletBalance = balance.balance
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // INSTANT/CONDITIONAL can close out on this call (deleted server-side and
    // archived to history), so a full reload — not a local mutation — keeps
    // the list correct.
    func complete(_ habit: Habit, apiClient: APIClient) async {
        errorMessage = nil
        do {
            try await apiClient.post("/habits/\(habit.id)/complete")
            await load(apiClient: apiClient)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func log(_ habit: Habit, completed: Bool, apiClient: APIClient) async {
        errorMessage = nil
        do {
            try await apiClient.post("/habits/\(habit.id)/log", body: LogHabitDayRequest(completed: completed))
            await load(apiClient: apiClient)
        } catch {
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
}
