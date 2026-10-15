import SwiftUI

/// The app's visual language: flat surfaces, hairline borders on light cards,
/// solid color blocks without borders, no drop shadows — calm enough to sit
/// next to the system's own glass tab bar. Color is spent on data (types,
/// difficulty, coins), not decoration.
enum Palette {
    /// Strong foreground for filled marks (checks, the selected day).
    static let ink = Color.primary.opacity(0.9)
    static let hairline = Color.primary.opacity(0.1)
    static let radius: CGFloat = 18

    static let teal = Color(red: 0.20, green: 0.68, blue: 0.62)
    static let purple = Color(red: 0.55, green: 0.40, blue: 0.90)
    static let yellow = Color(red: 0.96, green: 0.75, blue: 0.20)
    static let green = Color(red: 0.24, green: 0.68, blue: 0.38)
    static let red = Color(red: 0.90, green: 0.32, blue: 0.30)
}

extension View {
    /// A rounded surface. Light fills get a hairline border so they read on a
    /// white page; solid color blocks pass `bordered: false`.
    func card(
        fill: some ShapeStyle = Color(.systemBackground),
        radius: CGFloat = Palette.radius,
        bordered: Bool = true
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background(fill, in: shape)
            .overlay(shape.stroke(bordered ? Palette.hairline : .clear, lineWidth: 1))
    }
}

extension HabitType {
    /// Accent per type — the same colors everywhere a habit appears.
    var tint: Color {
        switch self {
        case .instant: .accentColor
        case .conditional: Palette.purple
        case .recurring: Palette.teal
        }
    }
}

extension HabitDifficulty {
    var tint: Color {
        switch self {
        case .easy: Palette.green
        case .medium: .orange
        case .hard: Palette.red
        }
    }

    /// 1–3: how many pips the difficulty meter fills.
    var level: Int {
        switch self {
        case .easy: 1
        case .medium: 2
        case .hard: 3
        }
    }
}
