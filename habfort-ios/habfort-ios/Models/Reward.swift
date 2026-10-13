import Foundation

struct Reward: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let name: String
    let costCoins: Int
    let archivedAt: String?
    let createdAt: String
    /// Starred as the main goal. Optional so older API responses still decode.
    let isGoal: Bool?
}

extension Array where Element == Reward {
    /// What the balance is working towards: the starred reward, otherwise the
    /// cheapest one.
    var goal: Reward? {
        first { $0.isGoal == true } ?? self.min { $0.costCoins < $1.costCoins }
    }
}
