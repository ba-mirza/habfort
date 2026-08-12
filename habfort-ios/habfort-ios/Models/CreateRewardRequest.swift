import Foundation

struct CreateRewardRequest: Encodable {
    let name: String
    let costCoins: Int
}
