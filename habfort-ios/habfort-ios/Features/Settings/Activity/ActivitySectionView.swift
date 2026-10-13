import SwiftUI

/// GitHub-style activity on the profile: a week table, a month calendar and
/// a year heatmap, with the period's totals underneath.
struct ActivitySectionView: View {
    @Bindable var viewModel: ActivityViewModel
    @Environment(APIClient.self) private var apiClient

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Период", selection: $viewModel.period) {
                ForEach(ActivityPeriod.allCases) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)

            switch viewModel.period {
            case .week: WeekActivityTable(viewModel: viewModel)
            case .month: MonthHeatmap(viewModel: viewModel)
            case .year: YearHeatmap(viewModel: viewModel)
            }

            HStack(spacing: 8) {
                statTile(title: "Выполнение", value: rateText)
                statTile(title: "Лучший день", value: bestDayText)
                statTile(title: "Всего", value: "\(viewModel.periodTotal)")
            }
        }
        .padding(.vertical, 6)
        .onChange(of: viewModel.period) {
            Task { await viewModel.loadDiscipline(apiClient: apiClient) }
        }
    }

    private var rateText: String {
        guard let rate = viewModel.periodDiscipline?.rate else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }

    private var bestDayText: String {
        guard let best = viewModel.periodBestDay else { return "—" }
        return "\(best.count) · \(best.date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "ru_RU"))))"
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
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// One heatmap square. Intensity is relative to the period's busiest day.
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
