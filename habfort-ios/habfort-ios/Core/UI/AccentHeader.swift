import SwiftUI

/// The orange block at the top of each main tab, bleeding under the status
/// bar with rounded bottom corners, over a faint tilted grid of activity
/// squares. Content sits on it in cards.
struct AccentHeader<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background {
            let shape = UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous)
            shape
                .fill(Palette.headerFill)
                .overlay { ActivityGridPattern().clipShape(shape) }
                .ignoresSafeArea(edges: .top)
        }
    }
}

/// GitHub-style contribution squares, tilted and barely visible — a nod to
/// the heatmap in the profile. Deterministic, so it doesn't shimmer between
/// renders.
private struct ActivityGridPattern: View {
    private let cell: CGFloat = 16
    private let gap: CGFloat = 5

    var body: some View {
        Canvas { context, size in
            let step = cell + gap
            // Oversized so the rotated grid still covers every corner.
            let extent = max(size.width, size.height) * 1.6
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.rotate(by: .degrees(-14))
            let count = Int(extent / step)
            for row in -count / 2...count / 2 {
                for column in -count / 2...count / 2 {
                    let level = Self.level(row: row, column: column)
                    guard level > 0 else { continue }
                    let rect = CGRect(x: CGFloat(column) * step, y: CGFloat(row) * step, width: cell, height: cell)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: 4),
                        with: .color(.white.opacity(0.02 + Double(level) * 0.025))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 0–4 activity level from a cheap integer hash of the cell position.
    private static func level(row: Int, column: Int) -> Int {
        var hash = UInt32(truncatingIfNeeded: row &* 73_856_093 ^ column &* 19_349_663)
        hash ^= hash >> 13
        hash = hash &* 0x5BD1_E995
        hash ^= hash >> 15
        return Int(hash % 5)
    }
}

/// Large screen title on the accent header.
struct AccentHeaderTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(Palette.onHeader)
    }
}

extension View {
    /// A card sitting in a plain List: no separators, no row background,
    /// side margins.
    func cardRow(top: CGFloat = 6) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
