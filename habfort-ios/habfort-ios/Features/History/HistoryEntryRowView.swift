import SwiftUI

/// A finished habit in History: type icon, name, details and what it paid.
/// Only a partial result gets a badge — "completed" is the normal case.
struct HistoryEntryRowView: View {
    let entry: HabitHistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.habitType.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(entry.habitType.tint)
                .frame(width: 34, height: 34)
                .card(fill: entry.habitType.tint.opacity(0.14), radius: 10, bordered: false)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.habitName)
                    .font(.body.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 3) {
                    Text("+\(entry.coinsAwarded)")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: "seal.fill")
                        .foregroundStyle(Palette.yellow)
                }
                if entry.status != .completed {
                    Text(entry.status.displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(entry.status.color)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .card()
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
