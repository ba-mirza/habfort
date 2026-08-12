import SwiftUI

/// One bar per day: height and color follow the share of that day's scheduled
/// habits that got done. Reads as rhythm — streaks and gaps are visible in one
/// glance, which a bar chart of totals can't show.
struct ActivityStrip: View {
    let days: [DisciplineStats.Day]
    var height: CGFloat = 44

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(days) { day in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color(for: day))
                    .frame(height: barHeight(for: day))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height, alignment: .bottom)
    }

    /// Days with nothing scheduled keep a flat stub so the timeline stays
    /// evenly spaced instead of collapsing.
    private func barHeight(for day: DisciplineStats.Day) -> CGFloat {
        guard let ratio = day.ratio else { return 3 }
        return max(4, height * ratio)
    }

    private func color(for day: DisciplineStats.Day) -> Color {
        guard let ratio = day.ratio else { return .secondary.opacity(0.25) }
        switch ratio {
        case ..<0.4: return .red.opacity(0.7)
        case ..<1: return .orange.opacity(0.85)
        default: return .green
        }
    }
}
