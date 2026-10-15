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
            ZStack {
                Circle()
                        .fill(isDone ? Brutal.green : Color(.systemBackground))
                    Circle()
                        .stroke(Brutal.ink, lineWidth: 2)
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 30, height: 30)
                .frame(width: 44, height: 44)

            Image(systemName: habit.type.iconName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .brutalCard(fill: habit.type.tint, radius: 10, shadow: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
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
                        .font(.system(.subheadline, design: .rounded, weight: .heavy))
                        .foregroundStyle(.primary)
                        .labelStyle(TrailingIconLabelStyle(iconColor: Brutal.yellow))
                    Text("+\(reward.xp) XP")
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                        .foregroundStyle(Brutal.purple)
                }
                .opacity(isDone ? 0.45 : 1)
                .overlay(alignment: .top) {
                    if floatingReward {
                        Text("+\(reward.coins)")
                            .font(.system(.headline, design: .rounded, weight: .heavy))
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
        .brutalCard(fill: isDone ? AnyShapeStyle(Brutal.green.opacity(0.1)) : AnyShapeStyle(Color(.systemBackground)))
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
