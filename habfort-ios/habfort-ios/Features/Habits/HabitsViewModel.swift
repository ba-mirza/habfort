import Foundation

@MainActor
@Observable
final class HabitsViewModel {
    private(set) var habits: [Habit] = []
    private(set) var isLoading = false
    var errorMessage: String?

    var typeFilter: HabitType?
    var difficultyFilter: HabitDifficulty?

    var filteredHabits: [Habit] {
        habits.filter { habit in
            (typeFilter == nil || habit.type == typeFilter)
                && (difficultyFilter == nil || habit.difficulty == difficultyFilter)
        }
    }

    func load(apiClient: APIClient) async {
        isLoading = true
        errorMessage = nil
        do {
            habits = try await apiClient.get("/habits")
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
