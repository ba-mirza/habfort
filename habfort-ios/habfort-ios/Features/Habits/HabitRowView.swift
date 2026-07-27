import SwiftUI

struct HabitRowView: View {
    let habit: Habit

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: typeIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(habit.difficulty.displayName)
                .font(.caption2.bold())
                .foregroundStyle(difficultyColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(difficultyColor.opacity(0.15), in: Capsule())
        }
        .padding(.vertical, 4)
    }

    private var typeIcon: String {
        switch habit.type {
        case .instant: "bolt.fill"
        case .conditional: "flame.fill"
        case .recurring: "arrow.triangle.2.circlepath"
        }
    }

    private var difficultyColor: Color {
        switch habit.difficulty {
        case .easy: .green
        case .medium: .orange
        case .hard: .red
        }
    }

    private var subtitle: String {
        switch habit.type {
        case .instant:
            "One-off"
        case .conditional:
            if let requiredDays = habit.requiredDays {
                "Day \(habit.currentStreak ?? 0) of \(requiredDays)"
            } else {
                "Streak"
            }
        case .recurring:
            scheduleDescription
        }
    }

    private var scheduleDescription: String {
        guard habit.scheduleType == .daysOfWeek, !habit.scheduleDays.isEmpty else {
            return "Every day"
        }
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return habit.scheduleDays.sorted().compactMap { symbols[safe: $0] }.joined(separator: ", ")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
