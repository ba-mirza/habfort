import SwiftUI

/// Mon–Sun strip pinned above the habits list: a dark check for days with a
/// completion, a flame for today, grey for days ahead. Any day can be selected
/// to look at it; only today's list is interactive.
struct WeekStripView: View {
    let days: [Date]
    @Binding var selectedDay: Date
    let hasCompletions: (Date) -> Bool

    // Fixed Russian labels (same as DayOfWeekPicker) rather than the device
    // locale — the app's UI is Russian-only.
    private static let weekdaySymbols = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]

    var body: some View {
        HStack(spacing: 4) {
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
        let isDone = !isFuture && hasCompletions(day)

        return Button {
            withAnimation(.snappy) { selectedDay = day }
        } label: {
            VStack(spacing: 6) {
                Text(Self.weekdaySymbols[calendar.component(.weekday, from: day) - 1])
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(isSelected ? Brutal.ink : .clear))

                circle(isToday: isToday, isFuture: isFuture, isDone: isDone)
                    .frame(width: 38, height: 38)

                Text(day.formatted(.dateTime.day()))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(isDone ? "есть выполнения" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func circle(isToday: Bool, isFuture: Bool, isDone: Bool) -> some View {
        if isToday {
            ZStack {
                Circle().fill(isDone ? Color.accentColor : Color(.systemBackground))
                Circle().stroke(Color.accentColor, lineWidth: 3)
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isDone ? .white : Color.accentColor)
                    .symbolEffect(.bounce, value: isDone)
            }
        } else if isDone {
            ZStack {
                Circle().fill(Brutal.ink)
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color(.systemBackground))
            }
        } else {
            Circle()
                .fill(Color.secondary.opacity(isFuture ? 0.12 : 0.2))
        }
    }
}
