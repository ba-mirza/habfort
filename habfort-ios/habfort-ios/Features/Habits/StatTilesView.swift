import SwiftUI

/// Three colored stat tiles under the header: streak, today, active.
struct StatTilesView: View {
    let streak: DayStreak?
    let doneToday: Int
    let dueToday: Int
    let activeCount: Int

    var body: some View {
        HStack(spacing: 12) {
            tile(value: "\(streak?.current ?? 0)", label: streakLabel, icon: "flame.fill", color: Brutal.purple)
            tile(value: "\(doneToday)/\(dueToday)", label: "Сегодня", icon: "checkmark.circle.fill", color: Brutal.teal)
            tile(value: "\(activeCount)", label: "Активных", icon: "list.bullet", color: .accentColor)
        }
    }

    private var streakLabel: String {
        let n = streak?.current ?? 0
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "день подряд" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "дня подряд" }
        return "дней подряд"
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
        .brutalCard(fill: LinearGradient(colors: [color, color.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing), radius: 16)
        .accessibilityElement(children: .combine)
    }
}
