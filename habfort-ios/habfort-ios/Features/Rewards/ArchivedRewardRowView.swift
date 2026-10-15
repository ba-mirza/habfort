import SwiftUI

struct ArchivedRewardRowView: View {
    let reward: Reward
    let onRestore: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .card(fill: Color.secondary.opacity(0.12), radius: 10, bordered: false)

            VStack(alignment: .leading, spacing: 2) {
                Text(reward.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 3) {
                    Text("\(reward.costCoins)")
                    Image(systemName: "seal.fill")
                    if let archivedAt = reward.archivedAt {
                        Text("· в архиве с \(ISO8601.shortDate(from: archivedAt))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onRestore) {
                Text("Вернуть")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .card()
    }
}
