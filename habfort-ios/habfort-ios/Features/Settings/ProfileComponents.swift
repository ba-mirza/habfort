import SwiftUI

/// Identity + level with the XP bar toward the next one.
struct LevelCard: View {
    let name: String
    let progress: ProgressStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Text(name.first.map { String($0).uppercased() } ?? "?")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .lineLimit(1)
                    Text("Уровень \(progress?.level ?? 1)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.purple)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(
                    value: Double(progress?.levelXp ?? 0),
                    total: Double(max(progress?.levelSpan ?? 1, 1))
                )
                .tint(Palette.purple)
                HStack {
                    Text("\(progress?.levelXp ?? 0) / \(progress?.levelSpan ?? 100) XP")
                    Spacer()
                    Text("до уровня \((progress?.level ?? 1) + 1)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .card()
    }
}

/// Solid stat tile: big number, label, icon in the corner.
struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .card(fill: color, radius: 16, bordered: false)
        .accessibilityElement(children: .combine)
    }
}

/// One achievement: colored badge when unlocked, grey with progress when not.
struct AchievementBadge: View {
    let achievement: ProgressStats.Achievement

    var body: some View {
        let entry = AchievementCatalog.entry(for: achievement.id)
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? entry.color : Color.secondary.opacity(0.12))
                if !achievement.unlocked {
                    Circle()
                        .trim(from: 0, to: Double(achievement.current) / Double(max(achievement.target, 1)))
                        .stroke(entry.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                Image(systemName: achievement.unlocked ? entry.icon : "lock.fill")
                    .font(.system(size: achievement.unlocked ? 22 : 16, weight: .semibold))
                    .foregroundStyle(achievement.unlocked ? .white : .secondary)
            }
            .frame(width: 58, height: 58)

            Text(entry.title)
                .font(.caption2.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .foregroundStyle(achievement.unlocked ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title). \(entry.detail)")
        .accessibilityValue(achievement.unlocked ? "получено" : "\(achievement.current) из \(achievement.target)")
    }
}
