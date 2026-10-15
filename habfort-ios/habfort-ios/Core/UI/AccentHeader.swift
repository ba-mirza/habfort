import SwiftUI

/// The orange block at the top of each main tab, bleeding under the status
/// bar with rounded bottom corners. Content sits on it in black/white cards.
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
            UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous)
                .fill(Color.accentColor)
                .ignoresSafeArea(edges: .top)
        }
    }
}

/// Large screen title on the accent header.
struct AccentHeaderTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(.black)
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
