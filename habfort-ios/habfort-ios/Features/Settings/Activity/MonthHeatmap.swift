import SwiftUI

/// Current month as a Monday-first calendar, each day shaded by completions.
struct MonthHeatmap: View {
    let viewModel: ActivityViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var cells: [Date?] {
        let calendar = WeekCalendar.calendar
        let (start, end) = ActivityPeriod.month.days
        // Weekday offset of the 1st in a Monday-first week.
        let offset = (calendar.component(.weekday, from: start) + 5) % 7
        var cells: [Date?] = Array(repeating: nil, count: offset)
        var day = start
        while day <= end {
            cells.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return cells
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(activityWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isFuture = day > Date()
        return HeatCell(count: viewModel.count(on: day), maxCount: viewModel.periodMax)
            .opacity(isFuture ? 0.4 : 1)
            .overlay {
                Text(day.formatted(.dateTime.day()))
                    .font(.caption2)
                    .foregroundStyle(viewModel.count(on: day) > 0 ? .white : .secondary)
            }
    }
}
