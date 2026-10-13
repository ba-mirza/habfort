import SwiftUI

/// Habits × days of the current week; a filled square is a completion.
struct WeekActivityTable: View {
    let viewModel: ActivityViewModel

    private var days: [Date] { WeekCalendar.days() }

    /// Habit name → indices (0 = Monday) of the days it was completed on.
    private var rows: [(name: String, done: Set<Int>)] {
        let calendar = WeekCalendar.calendar
        var byName: [String: Set<Int>] = [:]
        for entry in viewModel.weekEntries {
            guard let day = ISO8601.day(from: entry.endedAt),
                  let index = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: day) })
            else { continue }
            byName[entry.habitName, default: []].insert(index)
        }
        return byName.map { (name: $0.key, done: $0.value) }.sorted { $0.name < $1.name }
    }

    var body: some View {
        if rows.isEmpty {
            Text("На этой неделе пока ничего не выполнено.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else {
            Grid(horizontalSpacing: 4, verticalSpacing: 6) {
                GridRow {
                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                    ForEach(activityWeekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(rows, id: \.name) { row in
                    GridRow {
                        Text(row.name)
                            .font(.caption)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(0..<7, id: \.self) { index in
                            HeatCell(count: row.done.contains(index) ? 1 : 0, maxCount: 1, size: 22)
                        }
                    }
                }
            }
        }
    }
}
