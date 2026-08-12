import SwiftUI

// Shared icon/color language for habit type and difficulty, used by the
// type-filter cards on the Habits tab and the colored chip pickers in the
// create-habit form — kept in one place so both stay visually consistent.
extension HabitType {
    var iconName: String {
        switch self {
        case .instant: "bolt.fill"
        case .conditional: "flame.fill"
        case .recurring: "arrow.triangle.2.circlepath"
        }
    }

    var chipColors: (background: Color, foreground: Color) {
        switch self {
        case .instant:
            (Color(red: 0.82, green: 0.94, blue: 0.83), Color(red: 0.12, green: 0.42, blue: 0.22))
        case .conditional:
            (Color(red: 1.0, green: 0.9, blue: 0.76), Color(red: 0.55, green: 0.33, blue: 0.04))
        case .recurring:
            (Color(red: 0.86, green: 0.87, blue: 1.0), Color(red: 0.29, green: 0.24, blue: 0.66))
        }
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

    var chipColors: (background: Color, foreground: Color) {
        switch self {
        case .easy:
            (Color(red: 0.82, green: 0.94, blue: 0.83), Color(red: 0.12, green: 0.42, blue: 0.22))
        case .medium:
            (Color(red: 1.0, green: 0.9, blue: 0.76), Color(red: 0.55, green: 0.33, blue: 0.04))
        case .hard:
            (Color(red: 1.0, green: 0.82, blue: 0.82), Color(red: 0.6, green: 0.12, blue: 0.12))
        }
    }
}
