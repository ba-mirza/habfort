import Foundation

enum HabitHistoryStatus: String, Codable, CaseIterable, Identifiable {
    case completed = "COMPLETED"
    case notCompleted = "NOT_COMPLETED"
    case partial = "PARTIAL"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .completed: "Завершено"
        case .notCompleted: "Не выполнено"
        case .partial: "Частично"
        }
    }
}

struct HabitHistoryEntry: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let habitId: String?
    let habitName: String
    let habitType: HabitType
    let status: HabitHistoryStatus
    let daysCompleted: Int?
    let daysRequired: Int?
    let coinsAwarded: Int
    let startedAt: String
    let endedAt: String
}
