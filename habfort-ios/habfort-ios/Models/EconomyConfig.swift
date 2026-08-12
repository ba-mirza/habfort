import Foundation

/// Coin constants served by GET /economy. Fetched rather than hardcoded so the
/// numbers the app promises always match the ones the backend actually awards.
nonisolated struct EconomyConfig: Decodable {
    struct FullDayBonus: Decodable {
        let weekday: Int
        let weekend: Int
    }

    /// Keyed by `HabitDifficulty.rawValue` ("EASY", "MEDIUM", "HARD").
    let difficultyCoins: [String: Int]
    let fullDayBonus: FullDayBonus
    let rewardMinCostCoins: Int

    func coins(for difficulty: HabitDifficulty) -> Int? {
        difficultyCoins[difficulty.rawValue]
    }
}
