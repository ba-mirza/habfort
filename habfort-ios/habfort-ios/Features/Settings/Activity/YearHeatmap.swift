import SwiftUI

/// The trailing 52 weeks as GitHub's contribution grid: one column per week,
/// Monday on top, scrolled to the current week.
struct YearHeatmap: View {
    let viewModel: ActivityViewModel

    private let cellSize: CGFloat = 12
    private let spacing: CGFloat = 3

    private var weeks: [[Date]] {
        let calendar = WeekCalendar.calendar
        let (start, end) = ActivityViewModel.yearDays
        var weeks: [[Date]] = []
        var weekStart = start
        while weekStart <= end {
            let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
            weeks.append(week)
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else { break }
            weekStart = next
        }
        return weeks
    }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(Array(activityWeekdaySymbols.enumerated()), id: \.offset) { index, symbol in
                    Text(index.isMultiple(of: 2) ? symbol : "")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(height: cellSize)
                }
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                            VStack(spacing: spacing) {
                                ForEach(week, id: \.self) { day in
                                    HeatCell(count: viewModel.count(on: day), maxCount: viewModel.maxCount, size: cellSize)
                                        .opacity(day > Date() ? 0 : 1)
                                }
                            }
                            .id(index)
                        }
                    }
                }
                .onAppear { proxy.scrollTo(weeks.count - 1, anchor: .trailing) }
            }
        }
    }
}
