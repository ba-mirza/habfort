import SwiftUI

/// A habit as a card: checkbox, type icon, name with a difficulty meter, and
/// what completing it pays (coins + XP) on the right. Tapping anywhere on it
/// toggles completion; completing floats the reward up off the card.
struct HabitRowView: View {
    let habit: Habit
    let reward: (coins: Int, xp: Int)?
    var isPending = false
    let onToggle: () -> Void

    @State private var floatingReward = false

    private var isDone: Bool { habit.isCompletedToday == true }

    var body: some View {
        HStack(spacing: 12) {
            // Same mark as the week strip: an empty ring, filled dark with a
            // white check once done.
            ZStack {
                Circle()
                    .fill(isDone ? Palette.ink : .clear)
                Circle()
                    .stroke(isDone ? Palette.ink : Color.secondary.opacity(0.5), lineWidth: 1.5)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Color(.systemBackground))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 26, height: 26)
            .frame(width: 40, height: 44)

            Image(systemName: habit.type.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(habit.type.tint)
                .frame(width: 34, height: 34)
                .card(fill: habit.type.tint.opacity(0.14), radius: 10, bordered: false)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.body.weight(.medium))
                    .strikethrough(isDone, color: .secondary)
                    .foregroundStyle(isDone ? .secondary : .primary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    DifficultyMeter(difficulty: habit.difficulty)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            if let reward {
                VStack(alignment: .trailing, spacing: 3) {
                    Label("+\(reward.coins)", systemImage: "seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .labelStyle(TrailingIconLabelStyle(iconColor: Palette.yellow))
                    Text("+\(reward.xp) XP")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .opacity(isDone ? 0.45 : 1)
                .overlay(alignment: .top) {
                    if floatingReward {
                        Text("+\(reward.coins)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .transition(.asymmetric(
                                insertion: .offset(y: 0).combined(with: .opacity),
                                removal: .offset(y: -36).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.trailing, 14)
        .padding(.leading, 4)
        .card(fill: isDone ? Color.secondary.opacity(0.06) : Palette.surface)
        // The whole row is the toggle; editing lives in the trailing swipe.
        .contentShape(Rectangle())
        .onTapGesture { if !isPending { onToggle() } }
        .sensoryFeedback(.success, trigger: isDone) { _, done in done }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isDone ? "Отменить выполнение" : "Отметить выполненной")
        .onChange(of: isDone) { _, done in
            guard done else { return }
            floatingReward = true
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) { floatingReward = false }
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
        return habit.scheduleDays.sorted().compactMap { symbols.indices.contains($0) ? symbols[$0] : nil }.joined(separator: ", ")
    }
}

/// Difficulty as 1–3 filled pips in the difficulty's color instead of a word.
struct DifficultyMeter: View {
    let difficulty: HabitDifficulty

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { pip in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(pip <= difficulty.level ? difficulty.tint : Color.secondary.opacity(0.25))
                    .frame(width: 5, height: 4 + CGFloat(pip) * 3)
            }
        }
        .frame(height: 13, alignment: .bottom)
        .accessibilityElement()
        .accessibilityLabel("Сложность: \(difficulty.displayName)")
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    let iconColor: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.title
            configuration.icon.foregroundStyle(iconColor)
        }
    }
}
