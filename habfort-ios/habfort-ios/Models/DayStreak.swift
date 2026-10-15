import Foundation

/// GET /history/streak — days in a row with at least one completion.
nonisolated struct DayStreak: Decodable {
    let current: Int
    let best: Int
    let completedToday: Bool
}
