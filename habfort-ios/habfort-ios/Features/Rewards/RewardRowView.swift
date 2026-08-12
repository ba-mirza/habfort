import SwiftUI

struct RewardRowView: View {
    let reward: Reward
    let canAfford: Bool
    let missingCoins: Int
    let onRedeem: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(reward.name)
                    .font(.body)

                HStack(spacing: 4) {
                    Image(systemName: "seal.fill")
                    Text("\(reward.costCoins)")
                        .font(.subheadline.bold())

                    if !canAfford {
                        Text("· не хватает \(missingCoins)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(canAfford ? Color.accentColor : .secondary)
            }

            Spacer()

            Button(action: onRedeem) {
                Text("Потратить")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(canAfford ? Color.green : Color.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        (canAfford ? Color.green : Color.secondary).opacity(0.15),
                        in: Capsule()
                    )
            }
            // `.borderless` keeps the tap target on the button itself — a
            // plain button in a List row makes the whole row trigger it.
            .buttonStyle(.borderless)
            .disabled(!canAfford)
        }
        .padding(.vertical, 4)
    }
}
