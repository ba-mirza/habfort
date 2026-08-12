import Foundation

struct Redeem: Codable, Identifiable, Hashable {
    // Archived rewards are excluded from GET /rewards, so the name can't be
    // resolved from the rewards list — the backend embeds it here instead.
    struct RewardRef: Codable, Hashable {
        let id: String
        let name: String
    }

    let id: String
    let userId: String
    let rewardId: String
    let reward: RewardRef?
    let amountSpent: Int
    let redeemedAt: String

    var rewardName: String { reward?.name ?? "Награда" }
}
