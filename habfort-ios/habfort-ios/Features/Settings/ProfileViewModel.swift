import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var walletBalance: Int = 0
    private(set) var stats: HistoryStats?
    private(set) var isLoading = false
    var errorMessage: String?

    func load(apiClient: APIClient) async {
        isLoading = true
        errorMessage = nil
        do {
            async let balanceTask: WalletBalance = apiClient.get("/wallet/balance")
            async let statsTask: HistoryStats = apiClient.get("/history/stats")
            let (balance, fetchedStats) = try await (balanceTask, statsTask)
            walletBalance = balance.balance
            stats = fetchedStats
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
