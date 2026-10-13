import Foundation

/// The Monday-to-Sunday week the Habits tab's day strip shows, plus what each
/// day holds. Only today can be acted on; past days are read back from history
/// and future days are projected from the active habits' schedules.
enum WeekCalendar {
    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        return calendar
    }

    static func days(containing date: Date = Date()) -> [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }
}

enum DayHabitStatus {
    case done, missed, planned
}

struct DayHabitEntry: Identifiable {
    let id: String
    let name: String
    let type: HabitType
    let status: DayHabitStatus
}

extension HabitsViewModel {
    /// Read-only contents of a day other than today.
    func entries(for day: Date) -> [DayHabitEntry] {
        let calendar = WeekCalendar.calendar
        let day = calendar.startOfDay(for: day)
        let today = calendar.startOfDay(for: Date())
        guard day != today else { return [] }

        // Backend weekdays are 0=Sun..6=Sat; Calendar's are 1=Sun..7=Sat.
        let weekday = calendar.component(.weekday, from: day) - 1
        let active = habits.filter { habit in
            guard let created = ISO8601.day(from: habit.createdAt) else { return false }
            return created <= day
        }

        if day > today {
            return active.compactMap { habit in
                switch habit.type {
                case .instant:
                    return nil // no date of its own — it's always "today"
                case .recurring:
                    guard habit.scheduleType != .daysOfWeek || habit.scheduleDays.contains(weekday) else { return nil }
                case .conditional:
                    // Only within the challenge's remaining length.
                    guard let created = ISO8601.day(from: habit.createdAt),
                          let requiredDays = habit.requiredDays,
                          let last = calendar.date(byAdding: .day, value: requiredDays - 1, to: created),
                          day <= last
                    else { return nil }
                }
                return DayHabitEntry(id: habit.id, name: habit.name, type: habit.type, status: .planned)
            }
        }

        let closed = weekHistory.filter { ISO8601.day(from: $0.endedAt) == day }
        var entries = closed.map {
            DayHabitEntry(id: $0.id, name: $0.habitName, type: $0.habitType, status: .done)
        }
        let doneHabitIds = Set(closed.compactMap(\.habitId))
        for habit in active where !doneHabitIds.contains(habit.id) {
            switch habit.type {
            case .instant:
                continue
            case .conditional:
                // A challenge that's still running has, by definition, every
                // day since its start completed — a gap would have closed it.
                entries.append(DayHabitEntry(id: habit.id, name: habit.name, type: habit.type, status: .done))
            case .recurring:
                guard habit.scheduleType != .daysOfWeek || habit.scheduleDays.contains(weekday) else { continue }
                entries.append(DayHabitEntry(id: habit.id, name: habit.name, type: habit.type, status: .missed))
            }
        }
        return entries
    }

    /// Whether anything was completed on a past day — drives the strip's dot.
    func hasCompletions(on day: Date) -> Bool {
        let calendar = WeekCalendar.calendar
        let day = calendar.startOfDay(for: day)
        if calendar.isDateInToday(day) {
            return habits.contains { $0.isCompletedToday == true }
        }
        return day < Date() && weekHistory.contains { ISO8601.day(from: $0.endedAt) == day }
    }
}
