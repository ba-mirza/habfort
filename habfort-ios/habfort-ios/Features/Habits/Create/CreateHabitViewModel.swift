import Foundation

@MainActor
@Observable
final class CreateHabitViewModel {
    var name = ""
    var type: HabitType = .instant
    var difficulty: HabitDifficulty = .easy
    // A software `.numberPad` keyboard doesn't stop a hardware/Simulator
    // keyboard from typing letters, so filter on every edit rather than
    // relying on the keyboard type alone.
    var requiredDaysText = "" {
        didSet {
            let filtered = requiredDaysText.filter(\.isNumber)
            if filtered != requiredDaysText {
                requiredDaysText = filtered
            }
        }
    }
    var scheduleType: RecurringScheduleType = .daily
    var scheduleDays: Set<Int> = []

    var isSubmitting = false
    var errorMessage: String?

    private(set) var economy: EconomyConfig?

    private var requiredDays: Int? { Int(requiredDaysText) }

    /// Coins for the selected difficulty, once the constants have loaded.
    var coinsForSelectedDifficulty: Int? {
        economy?.coins(for: difficulty)
    }

    /// What a broken CONDITIONAL streak would pay out — the backend rounds
    /// `coins * daysDone / requiredDays`, so a long challenge makes each day
    /// worth less. Shown as a worked example for one completed day.
    var partialCoinsPerDay: Int? {
        guard type == .conditional,
              let coins = coinsForSelectedDifficulty,
              let requiredDays, requiredDays >= 1
        else { return nil }
        return Int((Double(coins) / Double(requiredDays)).rounded())
    }

    /// Silent on failure: the form still works without the constants, they
    /// only drive the explanatory section.
    func loadEconomy(apiClient: APIClient) async {
        guard economy == nil else { return }
        economy = try? await apiClient.get("/economy")
    }

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
