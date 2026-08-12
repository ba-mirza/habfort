import Foundation

nonisolated struct HistoryStats: Codable {
    struct StatusBreakdown: Codable, Identifiable {
        let status: HabitHistoryStatus
        let count: Int
        let coinsAwarded: Int
        var id: String { status.rawValue }
    }

    struct TypeBreakdown: Codable, Identifiable {
        let type: HabitType
        let count: Int
        let coinsAwarded: Int
        var id: String { type.rawValue }
    }

    let totalEntries: Int
    let totalCoinsAwarded: Int
    let byStatus: [StatusBreakdown]
    let byType: [TypeBreakdown]
}
