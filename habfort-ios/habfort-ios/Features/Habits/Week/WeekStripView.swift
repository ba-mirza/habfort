import SwiftUI

/// Mon–Sun strip pinned above the habits list. Any day can be selected to look at it;
/// only today's list is interactive.
struct WeekStripView: View {
    let days: [Date]
    @Binding var selectedDay: Date
    let hasCompletions: (Date) -> Bool

    // Fixed Russian labels (same as DayOfWeekPicker) rather than the device
    // locale — the app's UI is Russian-only.
    private static let weekdaySymbols = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.self) { day in
                dayCell(day)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let calendar = WeekCalendar.calendar
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
        let isToday = calendar.isDateInToday(day)
        let isFuture = day > Date() && !isToday

        return Button {
            withAnimation(.snappy) { selectedDay = day }
        } label: {
            VStack(spacing: 4) {
                Text(Self.weekdaySymbols[calendar.component(.weekday, from: day) - 1])
                    .font(.caption2.weight(.semibold))
                Text(day.formatted(.dateTime.day()))
                    .font(.subheadline.weight(isToday ? .bold : .medium))
                Circle()
                    .frame(width: 5, height: 5)
                    .opacity(hasCompletions(day) ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? Color.white : isToday ? Color.accentColor : Color.primary)
            .opacity(isFuture && !isSelected ? 0.45 : 1)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(isToday ? 0.12 : 0))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
