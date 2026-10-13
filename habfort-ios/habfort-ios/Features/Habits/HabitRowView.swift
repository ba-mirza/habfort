import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    var isPending = false
    let onToggle: () -> Void

    private var isDone: Bool { habit.isCompletedToday == true }

    var body: some View {
        HStack(spacing: 12) {
            // Reminders-style checkbox: completing is one deliberate tap.
            // Borderless so it wins over the row's own tap (which opens edit).
            Button(action: onToggle) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26))
                    .foregroundStyle(isDone ? Color.green : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(isPending)
            .sensoryFeedback(.success, trigger: isDone) { _, done in done }
            .accessibilityLabel(isDone ? "Отменить выполнение" : "Выполнить")

            VStack(alignment: .leading, spacing: 2) {
                Text(habit.name)
                    .font(.body)
                    .strikethrough(isDone, color: .secondary)
                    .foregroundStyle(isDone ? .secondary : .primary)
                Label(subtitle, systemImage: typeIcon)
                    .labelStyle(.titleAndIcon)
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
            "Разовая"
        case .conditional:
            if let requiredDays = habit.requiredDays {
                "День \(habit.currentStreak ?? 0) из \(requiredDays)"
            } else {
                "Челлендж"
            }
        case .recurring:
            scheduleDescription
        }
    }

    private var scheduleDescription: String {
        guard habit.scheduleType == .daysOfWeek, !habit.scheduleDays.isEmpty else {
            return "Каждый день"
        }
        let symbols = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
        return habit.scheduleDays.sorted().compactMap { symbols[safe: $0] }.joined(separator: ", ")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
