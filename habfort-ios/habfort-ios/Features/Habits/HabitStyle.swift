import SwiftUI

// Shared icon/color language for habit type and difficulty (the tints live
// in Palette.swift), used by the chip pickers in the habit forms.
extension HabitType {
    var iconName: String {
        switch self {
        case .instant: "bolt.fill"
        case .conditional: "flame.fill"
        case .recurring: "arrow.triangle.2.circlepath"
        }
    }

    /// Derived from the shared tint, so chips match cards everywhere.
    var chipColors: (background: Color, foreground: Color) {
        (tint.opacity(0.16), tint)
    }
}

extension HabitDifficulty {
    var iconName: String {
        switch self {
        case .easy: "leaf.fill"
        case .medium: "flame.fill"
        case .hard: "bolt.fill"
        }
    }

    /// Derived from the shared tint, so chips match cards everywhere.
    var chipColors: (background: Color, foreground: Color) {
        (tint.opacity(0.16), tint)
    }
}
