import Foundation

/// The window the History tab shows: a day, a month or a year, stepped with
/// ‹ › arrows. Never moves past the period containing today.
struct HistoryPeriod: Equatable {
    enum Granularity: String, CaseIterable, Identifiable {
        case day, month, year

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .day: "День"
            case .month: "Месяц"
            case .year: "Год"
            }
        }

        var component: Calendar.Component {
            switch self {
            case .day: .day
            case .month: .month
            case .year: .year
            }
        }
    }

    var granularity: Granularity = .month
    var anchor = Date()

    private var calendar: Calendar { WeekCalendar.calendar }

    var interval: DateInterval {
        calendar.dateInterval(of: granularity.component, for: anchor)
            ?? DateInterval(start: calendar.startOfDay(for: anchor), duration: 86_400)
    }

    var canGoForward: Bool {
        interval.end <= Date()
    }

    mutating func step(_ direction: Int) {
        anchor = calendar.date(byAdding: granularity.component, value: direction, to: anchor) ?? anchor
    }

    var title: String {
        let ru = ISO8601.russian
        switch granularity {
        case .day:
            if calendar.isDateInToday(anchor) { return "Сегодня" }
            if calendar.isDateInYesterday(anchor) { return "Вчера" }
            return anchor.formatted(.dateTime.day().month(.wide).year().locale(ru))
        case .month:
            // "LLLL" is the standalone month name: "Октябрь 2026", not "октября".
            let formatter = DateFormatter()
            formatter.locale = ru
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: anchor).capitalized(with: ru)
        case .year:
            return anchor.formatted(.dateTime.year().locale(ru))
        }
    }

    /// `from`/`to` query items for the history endpoints.
    var queryItems: String {
        let formatter = ISO8601DateFormatter()
        return "from=\(formatter.string(from: interval.start))&to=\(formatter.string(from: interval.end.addingTimeInterval(-0.001)))"
    }
}
