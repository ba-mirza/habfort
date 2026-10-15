import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var progress: ProgressStats?
    private(set) var streak: DayStreak?
    private(set) var discipline: DisciplineStats?
    var errorMessage: String?

    func load(apiClient: APIClient) async {
        errorMessage = nil
        do {
            async let progressTask: ProgressStats = apiClient.get("/progress")
            async let streakTask: DayStreak = apiClient.get("/history/streak")
            async let disciplineTask: DisciplineStats = apiClient.get("/history/discipline")
            (progress, streak, discipline) = try await (progressTask, streakTask, disciplineTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
