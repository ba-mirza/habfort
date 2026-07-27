import Foundation

struct CreateHabitRequest: Encodable {
    let name: String
    let type: HabitType
    let difficulty: HabitDifficulty
    let requiredDays: Int?
    let scheduleType: RecurringScheduleType?
    let scheduleDays: [Int]?
}
