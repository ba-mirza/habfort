import Foundation

enum ActivityPeriod: String, CaseIterable, Identifiable {
    case week, month, year

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: "Неделя"
        case .month: "Месяц"
        case .year: "Год"
        }
    }

    /// First and last day (inclusive) of the period that contains today. The
    /// year is the trailing 52 weeks, GitHub-style, not the calendar year.
    var days: (start: Date, end: Date) {
        let calendar = WeekCalendar.calendar
        let today = calendar.startOfDay(for: Date())
        switch self {
        case .week:
            let days = WeekCalendar.days()
            return (days.first ?? today, days.last ?? today)
        case .month:
            let interval = calendar.dateInterval(of: .month, for: today)
            let start = interval?.start ?? today
            let end = interval.flatMap { calendar.date(byAdding: .day, value: -1, to: $0.end) } ?? today
            return (start, end)
        case .year:
            let yearAgo = calendar.date(byAdding: .weekOfYear, value: -52, to: today) ?? today
            let start = calendar.dateInterval(of: .weekOfYear, for: yearAgo)?.start ?? yearAgo
            return (start, today)
        }
    }
}

/// Profile heatmap data. A year of per-day counts is loaded once and sliced
/// per period on the client; the completion rate depends on schedules, so
/// it's asked from the backend for each period.
@MainActor
@Observable
final class ActivityViewModel {
    var period: ActivityPeriod = .week
    private(set) var counts: [String: Int] = [:]
    private(set) var weekEntries: [HabitHistoryEntry] = []
    private(set) var periodDiscipline: DisciplineStats?
    var errorMessage: String?

    static func key(for date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func count(on day: Date) -> Int {
        counts[Self.key(for: day)] ?? 0
    }

    private var periodDays: [Date] {
        let calendar = WeekCalendar.calendar
        let (start, end) = period.days
        let last = min(end, calendar.startOfDay(for: Date()))
        var days: [Date] = []
        var day = start
        while day <= last {
            days.append(day)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return days
    }

    var periodTotal: Int {
        periodDays.reduce(0) { $0 + count(on: $1) }
    }

    var periodBestDay: (date: Date, count: Int)? {
        periodDays
            .map { (date: $0, count: count(on: $0)) }
            .filter { $0.count > 0 }
            .max { $0.count < $1.count }
    }

    /// Busiest day in the period, for scaling cell intensity.
    var periodMax: Int {
        periodBestDay?.count ?? 0
    }

    func load(apiClient: APIClient) async {
        errorMessage = nil
        let week = ActivityPeriod.week.days
        do {
            async let activityTask: ActivityStats = apiClient.get(
                "/history/activity?from=\(Self.key(for: ActivityPeriod.year.days.start))&to=\(Self.key(for: Date()))"
            )
            async let weekTask: [HabitHistoryEntry] = apiClient.get(
                "/history?take=100&from=\(Self.iso(week.start))&to=\(Self.iso(Self.nextDay(week.end)))"
            )
            let (activity, entries) = try await (activityTask, weekTask)
            counts = Dictionary(activity.byDay.map { ($0.date, $0.count) }, uniquingKeysWith: +)
            weekEntries = entries
        } catch {
            errorMessage = error.localizedDescription
        }
        await loadDiscipline(apiClient: apiClient)
    }

    func loadDiscipline(apiClient: APIClient) async {
        let (start, end) = period.days
        let last = min(end, WeekCalendar.calendar.startOfDay(for: Date()))
        periodDiscipline = try? await apiClient.get(
            "/history/discipline?from=\(Self.key(for: start))&to=\(Self.key(for: last))"
        )
    }

    private static func nextDay(_ date: Date) -> Date {
        WeekCalendar.calendar.date(byAdding: .day, value: 1, to: date) ?? date
    }

    private static func iso(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}
