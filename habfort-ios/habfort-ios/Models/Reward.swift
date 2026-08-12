import Foundation

struct Reward: Codable, Identifiable, Hashable {
    let id: String
    let userId: String
    let name: String
    let costCoins: Int
    let archivedAt: String?
    let createdAt: String
}
