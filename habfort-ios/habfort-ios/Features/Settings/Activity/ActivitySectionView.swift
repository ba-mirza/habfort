import SwiftUI

/// GitHub-style year of activity on the profile, with the year's totals.
struct ActivitySectionView: View {
    let viewModel: ActivityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            YearHeatmap(viewModel: viewModel)

            HStack(spacing: 8) {
                statTile(title: "Выполнение", value: rateText)
                statTile(title: "Лучший день", value: bestDayText)
                statTile(title: "Всего", value: "\(viewModel.total)")
            }
        }
    }

    private var rateText: String {
        guard let rate = viewModel.discipline?.rate else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }

    private var bestDayText: String {
        guard let best = viewModel.bestDay else { return "—" }
        return "\(best.count) · \(best.date.formatted(.dateTime.day().month(.abbreviated).locale(ISO8601.russian)))"
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// One heatmap square. Intensity is relative to the busiest day.
struct HeatCell: View {
    let count: Int
    let maxCount: Int
    var size: CGFloat? = nil

    private var level: Int {
        guard count > 0, maxCount > 0 else { return 0 }
        return min(4, Int((Double(count) / Double(maxCount) * 4).rounded(.up)))
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(level == 0 ? Color.secondary.opacity(0.15) : Color.green.opacity([0, 0.3, 0.5, 0.75, 1][level]))
            .frame(width: size, height: size)
            .aspectRatio(1, contentMode: .fit)
    }
}

let activityWeekdaySymbols = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
