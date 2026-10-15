import SwiftUI

/// Three colored stat tiles under the header: streak, today, active.
struct StatTilesView: View {
    let streak: DayStreak?
    let doneToday: Int
    let dueToday: Int
    let activeCount: Int

    var body: some View {
        HStack(spacing: 12) {
            tile(value: "\(streak?.current ?? 0)", label: streakLabel, icon: "flame.fill", color: Palette.purple)
            tile(value: "\(doneToday)/\(dueToday)", label: "Сегодня", icon: "checkmark.circle.fill", color: Palette.teal)
            tile(value: "\(activeCount)", label: "Активных", icon: "list.bullet", color: .accentColor)
        }
    }

    private var streakLabel: String {
        russianPlural(streak?.current ?? 0, one: "день подряд", few: "дня подряд", many: "дней подряд")
    }

    private func tile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .trailing)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .card(fill: color, radius: 16, bordered: false)
        .accessibilityElement(children: .combine)
    }
}
