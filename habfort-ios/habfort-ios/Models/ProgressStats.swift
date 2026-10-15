import Foundation

/// GET /progress — level, XP and achievements, all derived on the backend.
nonisolated struct ProgressStats: Decodable {
    struct Metrics: Decodable {
        let completions: Int
        let bestStreak: Int
        let redeems: Int
        let challengesCompleted: Int
        let fullDays: Int
        let coinsEarned: Int
    }

    struct Achievement: Decodable, Identifiable {
        let id: String
        let current: Int
        let target: Int
        let unlocked: Bool
    }

    let xp: Int
    let level: Int
    let levelXp: Int
    let levelSpan: Int
    let metrics: Metrics
    let achievements: [Achievement]
}
