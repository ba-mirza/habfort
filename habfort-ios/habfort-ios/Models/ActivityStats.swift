import Foundation

/// GET /history/activity — completions per calendar day (only non-empty days).
nonisolated struct ActivityStats: Decodable {
    struct Day: Decodable {
        let date: String
        let count: Int
    }

    let from: String
    let to: String
    let total: Int
    let bestDay: Day?
    let byDay: [Day]
}
