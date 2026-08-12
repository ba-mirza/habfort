import Foundation

// The project builds with `-default-isolation=MainActor`, which would make the
// Decodable conformance main-actor isolated and unusable from the nonisolated
// decoding context inside APIClient.
nonisolated struct WalletBalance: Decodable {
    let balance: Int
}
