import SwiftUI

/// Composition of the active habit set as one stacked bar, using the same
/// per-type colors as the habit chips elsewhere in the app.
struct HabitCompositionBar: View {
    let counts: [(type: HabitType, count: Int)]

    private var total: Int {
        counts.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                HStack(spacing: 2) {
                    ForEach(counts, id: \.type) { entry in
                        Capsule()
                            .fill(entry.type.chipColors.foreground)
                            .frame(width: width(for: entry.count, in: proxy.size.width))
                    }
                }
            }
            .frame(height: 10)

            HStack(spacing: 12) {
                ForEach(counts, id: \.type) { entry in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(entry.type.chipColors.foreground)
                            .frame(width: 7, height: 7)
                        Text("\(entry.type.displayName) \(entry.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func width(for count: Int, in totalWidth: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        // Spacing between segments is taken off the available width first so
        // the segments always add up to the full bar.
        let spacing = CGFloat(max(0, counts.count - 1)) * 2
        return (totalWidth - spacing) * CGFloat(count) / CGFloat(total)
    }
}
