import SwiftUI

/// The shared shell for the main tabs: a colored header with a rounded content
/// "sheet" sliding over it. Extracted from the Habits tab so Rewards and
/// History read as the same app rather than three separate screens.
///
/// The header is taller than the part that stays visible above the sheet — the
/// rest hides behind it, which is what makes the list read as merging into the
/// header. Both heights are measured from the safe-area top; only the color
/// fill bleeds further up behind the status bar/Dynamic Island.
struct HeaderSheetScreen<Header: View, Accessory: View, Rows: View>: View {
    private let title: String
    private let headerHeight: CGFloat
    private let headerPeekHeight: CGFloat
    private let onRefresh: () async -> Void
    private let header: Header
    private let accessory: Accessory
    private let rows: Rows

    init(
        title: String,
        headerHeight: CGFloat = 190,
        headerPeekHeight: CGFloat = 140,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder header: () -> Header,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder rows: () -> Rows
    ) {
        self.title = title
        self.headerHeight = headerHeight
        self.headerPeekHeight = headerPeekHeight
        self.onRefresh = onRefresh
        self.header = header()
        self.accessory = accessory()
        self.rows = rows()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                // `.frame(height:)` + `.ignoresSafeArea` doesn't add the
                // safe-area amount on top of the given height, it eats into it
                // — so the fill would end before the sheet even starts, leaving
                // nothing behind the rounded corner to show it against. Adding
                // the real inset back guarantees the fill reaches past the sheet.
                Color.accentColor
                    .frame(height: headerHeight + proxy.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    Spacer(minLength: 0)
                }
                .frame(height: headerHeight)

                sheet
                    .padding(.top, headerPeekHeight)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.title3.bold())
                Spacer()
                accessory
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 4)

            List {
                rows
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable { await onRefresh() }
        }
        .background(Color(.systemBackground))
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous))
    }
}

extension HeaderSheetScreen where Accessory == EmptyView {
    init(
        title: String,
        headerHeight: CGFloat = 190,
        headerPeekHeight: CGFloat = 140,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder header: () -> Header,
        @ViewBuilder rows: () -> Rows
    ) {
        self.init(
            title: title,
            headerHeight: headerHeight,
            headerPeekHeight: headerPeekHeight,
            onRefresh: onRefresh,
            header: header,
            accessory: { EmptyView() },
            rows: rows
        )
    }
}
