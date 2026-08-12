import Foundation

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
        errorMessage = nil
        do {
            try await apiClient.delete("/habits/\(habit.id)")
            habits.removeAll { $0.id == habit.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
