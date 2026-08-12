import SwiftUI

/// Header for the Rewards tab: the balance is the number that decides whether
/// anything on this screen is affordable, so it's the headline.
struct RewardsHeaderView: View {
    let walletBalance: Int
    let spentTotal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Доступно жетонов")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 6) {
                Image(systemName: "seal.fill")
                    .font(.title3)
                Text("\(walletBalance)")
                    .font(.largeTitle.bold())
            }
            .foregroundStyle(.white)

            if spentTotal > 0 {
                Text("Всего потрачено: \(spentTotal)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
