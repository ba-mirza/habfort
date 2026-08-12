import SwiftUI

struct ArchivedRewardRowView: View {
    let reward: Reward
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(Color.secondary.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(reward.name)
                    .font(.body)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "seal.fill")
                    Text("\(reward.costCoins)")
                        .font(.subheadline.bold())
                    if let archivedAt = reward.archivedAt {
                        Text("· в архиве с \(ISO8601.shortDate(from: archivedAt))")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onRestore) {
                Text("Вернуть")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}
