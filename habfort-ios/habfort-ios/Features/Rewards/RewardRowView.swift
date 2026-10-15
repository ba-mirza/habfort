import SwiftUI

/// A wishlist reward: name, price, and how far the balance is from it — the
/// distance is what keeps people going, so every reward shows its own bar.
struct RewardRowView: View {
    let reward: Reward
    let balance: Int
    let onRedeem: () -> Void

    private var canAfford: Bool { balance >= reward.costCoins }

    private var progress: Double {
        reward.costCoins > 0 ? min(1, Double(balance) / Double(reward.costCoins)) : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.yellow)
                    .frame(width: 34, height: 34)
                    .card(fill: Palette.yellow.opacity(0.16), radius: 10, bordered: false)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(reward.name)
                            .font(.body.weight(.medium))
                            .lineLimit(2)
                        if reward.isGoal == true {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Palette.yellow)
                                .accessibilityLabel("Главная цель")
                        }
                    }
                    HStack(spacing: 3) {
                        Text("\(reward.costCoins)")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "seal.fill")
                            .font(.caption)
                            .foregroundStyle(Palette.yellow)
                        if !canAfford {
                            Text("· не хватает \(reward.costCoins - balance)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Button(action: onRedeem) {
                    Text("Потратить")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(canAfford ? Color.white : Color.secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(canAfford ? Color.accentColor : Color.secondary.opacity(0.12), in: Capsule())
                }
                // `.borderless` keeps the tap target on the button itself — a
                // plain button in a List row makes the whole row trigger it.
                .buttonStyle(.borderless)
                .disabled(!canAfford)
            }

            if !canAfford {
                ProgressView(value: progress)
                    .tint(Color.accentColor)
                    .accessibilityLabel("Прогресс до награды")
            }
        }
        .padding(14)
        .card()
    }
}
