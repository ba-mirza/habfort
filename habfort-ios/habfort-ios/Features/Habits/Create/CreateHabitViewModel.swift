import Foundation

@MainActor
@Observable
final class CreateHabitViewModel {
    var name = ""
    var type: HabitType = .instant
    var difficulty: HabitDifficulty = .easy
    var requiredDaysText = ""
    var scheduleType: RecurringScheduleType = .daily
    var scheduleDays: Set<Int> = []

    var isSubmitting = false
    var errorMessage: String?

    private var requiredDays: Int? { Int(requiredDaysText) }

    /// Mirrors the backend's `HabitFieldsMatchTypeConstraint`: requiredDays only for
    /// CONDITIONAL, scheduleType only for RECURRING, scheduleDays only for DAYS_OF_WEEK.
    var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        switch type {
        case .instant:
            return true
        case .conditional:
            guard let requiredDays else { return false }
            return requiredDays >= 1
        case .recurring:
            if scheduleType == .daysOfWeek {
                return !scheduleDays.isEmpty
            }
            return true
        }
    }

    @discardableResult
    func submit(apiClient: APIClient) async -> Bool {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let request = CreateHabitRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type,
            difficulty: difficulty,
            requiredDays: type == .conditional ? requiredDays : nil,
            scheduleType: type == .recurring ? scheduleType : nil,
            scheduleDays: type == .recurring && scheduleType == .daysOfWeek
                ? scheduleDays.sorted() : nil
        )

        do {
            let _: Habit = try await apiClient.post("/habits", body: request)
            reset()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func reset() {
        name = ""
        type = .instant
        difficulty = .easy
        requiredDaysText = ""
        scheduleType = .daily
        scheduleDays = []
    }
}
