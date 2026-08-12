import Foundation

@MainActor
@Observable
final class CreateRewardViewModel {
    var name = ""
    // A software `.numberPad` keyboard doesn't stop a hardware/Simulator
    // keyboard from typing letters, so filter on every edit rather than
    // relying on the keyboard type alone.
    var costCoinsText = "" {
        didSet {
            let filtered = costCoinsText.filter(\.isNumber)
            if filtered != costCoinsText {
                costCoinsText = filtered
            }
        }
    }

    var isSubmitting = false
    var errorMessage: String?

    private(set) var minCostCoins = 100

    private var costCoins: Int? { Int(costCoinsText) }

    // The floor is enforced server-side (it's the whole point — the user can't
    // just lower it on themselves), this just avoids a round trip for the
    // obviously-invalid case. The value is fetched so the hint and the check
    // can't drift from the backend config; 100 is only the pre-load default.
    var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let costCoins else { return false }
        return costCoins >= minCostCoins
    }

    func loadEconomy(apiClient: APIClient) async {
        guard let economy: EconomyConfig = try? await apiClient.get("/economy") else { return }
        minCostCoins = economy.rewardMinCostCoins
    }

    @discardableResult
    func submit(apiClient: APIClient) async -> Bool {
        guard let costCoins else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let request = CreateRewardRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            costCoins: costCoins
        )

        do {
            let _: Reward = try await apiClient.post("/rewards", body: request)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
