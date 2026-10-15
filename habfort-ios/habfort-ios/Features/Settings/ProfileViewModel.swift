import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var me: Me?
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
            async let meTask: Me = apiClient.get("/me")
            (progress, streak, discipline, me) = try await (progressTask, streakTask, disciplineTask, meTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
