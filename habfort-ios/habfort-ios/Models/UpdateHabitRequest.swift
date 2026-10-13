import Foundation

/// Nil fields are left out of the JSON, so the backend only touches what's sent.
struct UpdateHabitRequest: Encodable {
    let name: String
    let difficulty: HabitDifficulty?
    let scheduleType: RecurringScheduleType?
    let scheduleDays: [Int]?
}
