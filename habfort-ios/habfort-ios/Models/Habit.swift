import Foundation

enum HabitType: String, Codable, CaseIterable, Identifiable {
    case instant = "INSTANT"
    case conditional = "CONDITIONAL"
    case recurring = "RECURRING"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instant: "One-off"
        case .conditional: "Streak"
        case .recurring: "Recurring"
        }
    }
}

enum HabitDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "EASY"
    case medium = "MEDIUM"
    case hard = "HARD"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
}

enum RecurringScheduleType: String, Codable {
    case daily = "DAILY"
    case daysOfWeek = "DAYS_OF_WEEK"
}

struct Habit: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let name: String
    let type: HabitType
    let difficulty: HabitDifficulty
    let requiredDays: Int?
    let scheduleType: RecurringScheduleType?
    let scheduleDays: [Int]
    let status: String
    let createdAt: String
    var currentStreak: Int?
    var isCompletedToday: Bool?
}
