import SwiftUI

/// Profile hero: avatar with the plan badge, name, the copyable public id,
/// and the level with a dashed XP bar toward the next one.
struct ProfileHeader: View {
    let name: String
    let publicId: String?
    let progress: ProgressStats?
    let onOpenPro: () -> Void
    let onOpenSettings: () -> Void

    @State private var copied = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button(action: onOpenPro) {
                    Label("PRO", systemImage: "crown.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.accentColor.opacity(0.14), in: Capsule())
                }
                .buttonStyle(.plain)
                Spacer()
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(width: 38, height: 38)
                        .background(Color.secondary.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Настройки")
            }

            ZStack(alignment: .bottom) {
                Text(name.first.map { String($0).uppercased() } ?? "?")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 104, height: 104)
                    .background(Color.accentColor, in: Circle())
                // Everyone is on the free plan until subscriptions ship.
                Text("FREE")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.gray, in: Capsule())
                    .offset(y: 10)
            }
            .padding(.bottom, 8)

            VStack(spacing: 4) {
                Text(name)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .lineLimit(1)
                if let publicId {
                    Button {
                        UIPasteboard.general.string = publicId
                        copied = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(publicId)
                                .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.footnote)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .sensoryFeedback(.success, trigger: copied) { _, now in now }
                    .accessibilityLabel("ID \(publicId), скопировать")
                    .task(id: copied) {
                        guard copied else { return }
                        try? await Task.sleep(for: .seconds(1.5))
                        copied = false
                    }
                }
            }

            LevelProgress(progress: progress)
                .padding(.top, 6)
        }
    }
}

/// Level with XP drawn as a dashed line: one dash per 5% of the level.
private struct LevelProgress: View {
    let progress: ProgressStats?
    private let dashes = 20

    private var filled: Int {
        guard let progress, progress.levelSpan > 0 else { return 0 }
        return min(dashes, Int((Double(progress.levelXp) / Double(progress.levelSpan) * Double(dashes)).rounded(.down)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Уровень \(progress?.level ?? 1)")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Palette.purple)
                Spacer()
                Text("\(progress?.levelXp ?? 0) / \(progress?.levelSpan ?? 100) XP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 3) {
                ForEach(0..<dashes, id: \.self) { index in
                    Capsule()
                        .fill(index < filled ? Palette.purple : Color.secondary.opacity(0.18))
                        .frame(height: 6)
                }
            }
            Text("до уровня \((progress?.level ?? 1) + 1)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .card()
        .accessibilityElement(children: .combine)
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
