import Foundation

enum HabitType: String, Codable, CaseIterable, Identifiable {
    case instant = "INSTANT"
    case conditional = "CONDITIONAL"
    case recurring = "RECURRING"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instant: "Разовые"
        case .conditional: "Челленджи"
        case .recurring: "Регулярные"
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
        case .easy: "Лёгкая"
        case .medium: "Средняя"
        case .hard: "Сложная"
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

    // DAILY recurring habits and non-recurring types are always "due"; a
    // DAYS_OF_WEEK habit is only due on its scheduled weekdays. Mirrors the
    // backend's `assertScheduledOn` gating in HabitsService.
    var isScheduledToday: Bool {
        guard type == .recurring, scheduleType == .daysOfWeek else { return true }
        let todayWeekday = Calendar.current.component(.weekday, from: Date()) - 1
        return scheduleDays.contains(todayWeekday)
    }
}
