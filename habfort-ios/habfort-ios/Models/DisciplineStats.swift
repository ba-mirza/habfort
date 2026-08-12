import Foundation

/// GET /history/discipline — completed vs. scheduled habit-days over a window.
nonisolated struct DisciplineStats: Decodable {
    struct Day: Decodable, Identifiable {
        let date: String
        let planned: Int
        let completed: Int

        var id: String { date }

        /// Nil when nothing was scheduled — an empty day must not look like a
        /// failed one.
        var ratio: Double? {
            planned > 0 ? Double(completed) / Double(planned) : nil
        }
    }

    let from: String
    let to: String
    let totalPlanned: Int
    let totalCompleted: Int
    /// Nil when nothing was scheduled in the whole window.
    let rate: Double?
    let byDay: [Day]
}
