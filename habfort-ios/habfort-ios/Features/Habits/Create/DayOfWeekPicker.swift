import SwiftUI

struct DayOfWeekPicker: View {
    @Binding var selection: Set<Int>

    private let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { day in
                dayButton(day)
            }
        }
    }

    private func dayButton(_ day: Int) -> some View {
        let isSelected = selection.contains(day)
        return Button {
            if isSelected {
                selection.remove(day)
            } else {
                selection.insert(day)
            }
        } label: {
            Text(symbols[day])
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }
}
