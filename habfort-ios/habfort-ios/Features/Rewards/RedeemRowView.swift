import SwiftUI

struct RedeemRowView: View {
    let redeem: Redeem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 30, height: 30)
                .background(Color.green.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(redeem.rewardName)
                    .font(.body)
                Text(ISO8601.shortDate(from: redeem.redeemedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "seal.fill")
                Text("−\(redeem.amountSpent)")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
