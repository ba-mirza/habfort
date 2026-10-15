import SwiftUI

/// The app's visual language: light surfaces, a thin ink outline and a hard,
/// unblurred offset shadow (neo-brutalism, kept restrained — thin strokes, no
/// cartoon art). "Ink" is the primary label color, so the outline flips to
/// light in dark mode and the look survives both themes.
enum Brutal {
    static let ink = Color.primary.opacity(0.9)
    static let stroke: CGFloat = 1.5
    static let shadowOffset: CGFloat = 3
    static let radius: CGFloat = 18

    static let teal = Color(red: 0.25, green: 0.75, blue: 0.68)
    static let purple = Color(red: 0.62, green: 0.45, blue: 0.95)
    static let yellow = Color(red: 0.98, green: 0.79, blue: 0.25)
    static let green = Color(red: 0.27, green: 0.74, blue: 0.40)
    static let red = Color(red: 0.93, green: 0.33, blue: 0.31)
}

extension View {
    /// Outlined card with the hard offset shadow.
    func brutalCard(
        fill: some ShapeStyle = Color(.systemBackground),
        radius: CGFloat = Brutal.radius,
        shadow: CGFloat = Brutal.shadowOffset
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background(fill, in: shape)
            // Opaque base so a translucent tint doesn't show the shadow through.
            .background(Color(.systemBackground), in: shape)
            .overlay(shape.stroke(Brutal.ink, lineWidth: Brutal.stroke))
            .background(shape.fill(Brutal.ink).offset(x: shadow, y: shadow))
    }
}

extension HabitType {
    /// Card accent per type — the same colors everywhere a habit appears.
    var tint: Color {
        switch self {
        case .instant: .accentColor
        case .conditional: Brutal.purple
        case .recurring: Brutal.teal
        }
    }
}

extension HabitDifficulty {
    var tint: Color {
        switch self {
        case .easy: Brutal.green
        case .medium: .orange
        case .hard: Brutal.red
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
