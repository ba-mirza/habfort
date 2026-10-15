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

    /// Card surface: white in light mode, the elevated grey in dark mode —
    /// pure black cards on a black page read as holes, not surfaces.
    static let surface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .secondarySystemBackground : .systemBackground
    })

    /// The orange header block: a deeper orange in dark mode, so white text
    /// on it stays readable and it doesn't glare against the black page.
    static let headerFill = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.80, green: 0.36, blue: 0.09, alpha: 1)
            : UIColor(red: 0.95, green: 0.45, blue: 0.12, alpha: 1)
    })

    /// Text on the header: black on the light-mode orange, white on the
    /// deeper dark-mode one.
    static let onHeader = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : .black
    })

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
        fill: some ShapeStyle = Palette.surface,
        radius: CGFloat = Palette.radius,
        bordered: Bool = true
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background(fill, in: shape)
            // Opaque base so a translucent tint still reads as a surface.
            .background(Palette.surface, in: shape)
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
