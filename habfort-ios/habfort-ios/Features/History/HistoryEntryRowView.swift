import SwiftUI

struct HistoryEntryRowView: View {
    let entry: HabitHistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.habitType.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.habitName)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.status.displayName)
                    .font(.caption2.bold())
                    .foregroundStyle(entry.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(entry.status.color.opacity(0.15), in: Capsule())

                HStack(spacing: 4) {
                    Image(systemName: "seal.fill")
                    Text("\(entry.coinsAwarded)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        var parts = [entry.habitType.displayName]
        if let daysCompleted = entry.daysCompleted, let daysRequired = entry.daysRequired {
            parts.append("\(daysCompleted) из \(daysRequired) дней")
        }
        // Only the time — the day is already the section header above.
        let time = ISO8601.time(from: entry.endedAt)
        if !time.isEmpty {
            parts.append(time)
        }
        return parts.joined(separator: " · ")
    }
}
