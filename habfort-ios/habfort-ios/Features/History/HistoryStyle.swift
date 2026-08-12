import SwiftUI

extension HabitHistoryStatus {
    var color: Color {
        switch self {
        case .completed: .green
        case .partial: .orange
        case .notCompleted: .red
        }
    }
}
