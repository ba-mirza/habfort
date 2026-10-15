import Foundation

/// Profile heatmap: the trailing 52 weeks of per-day completion counts, plus
/// the completion rate over the same window (which depends on schedules, so
/// the backend computes it).
@MainActor
@Observable
final class ActivityViewModel {
    private(set) var counts: [String: Int] = [:]
    private(set) var discipline: DisciplineStats?
    var errorMessage: String?

    /// First and last day of the grid: Monday 52 weeks back through today.
    static var yearDays: (start: Date, end: Date) {
        let calendar = WeekCalendar.calendar
        let today = calendar.startOfDay(for: Date())
        let yearAgo = calendar.date(byAdding: .weekOfYear, value: -52, to: today) ?? today
        let start = calendar.dateInterval(of: .weekOfYear, for: yearAgo)?.start ?? yearAgo
        return (start, today)
    }

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

    var total: Int {
        counts.values.reduce(0, +)
    }

    var bestDay: (date: Date, count: Int)? {
        guard let best = counts.max(by: { $0.value < $1.value }), best.value > 0,
              let date = Self.dayKeyFormatter.date(from: best.key)
        else { return nil }
        return (date, best.value)
    }

    /// Busiest day, for scaling cell intensity.
    var maxCount: Int {
        counts.values.max() ?? 0
    }

    func load(apiClient: APIClient) async {
        errorMessage = nil
        let (start, end) = Self.yearDays
        let range = "from=\(Self.key(for: start))&to=\(Self.key(for: end))"
        do {
            async let activityTask: ActivityStats = apiClient.get("/history/activity?\(range)")
            async let disciplineTask: DisciplineStats = apiClient.get("/history/discipline?\(range)")
            let (activity, fetchedDiscipline) = try await (activityTask, disciplineTask)
            counts = Dictionary(activity.byDay.map { ($0.date, $0.count) }, uniquingKeysWith: +)
            discipline = fetchedDiscipline
        } catch {
            errorMessage = UserFacingError.message(for: error)
        }
    }
}
