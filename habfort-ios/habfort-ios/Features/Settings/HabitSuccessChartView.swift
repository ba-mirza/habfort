import Charts
import SwiftUI

struct HabitSuccessChartView: View {
    let stats: HistoryStats

    var body: some View {
        Chart(stats.byStatus) { row in
            BarMark(
                x: .value("Статус", row.status.displayName),
                y: .value("Количество", row.count)
            )
            .foregroundStyle(row.status.color)
            .cornerRadius(6)
        }
        .frame(height: 160)
    }
}
