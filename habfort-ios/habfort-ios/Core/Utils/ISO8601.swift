import Foundation

/// The API returns timestamps as ISO-8601 with fractional seconds
/// ("2026-08-12T10:00:00.000Z"), which the plain `.iso8601` decoding strategy
/// rejects — that's why the models keep these fields as `String`. Views that
/// need a real date (grouping, formatting) parse them through here.
enum ISO8601 {
    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plain = ISO8601DateFormatter()

    static func date(from string: String) -> Date? {
        withFractionalSeconds.date(from: string) ?? plain.date(from: string)
    }

    /// "12 авг" / "12 авг 2025" — the year is dropped for the current year to
    /// keep list rows short.
    static func shortDate(from string: String) -> String {
        guard let date = date(from: string) else { return "" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "сегодня" }
        if calendar.isDateInYesterday(date) { return "вчера" }

        // `.year(.omitted)` is iOS 18+, so the year is left out by simply not
        // adding the field to the format.
        return isCurrentYear(date)
            ? date.formatted(.dateTime.day().month(.abbreviated))
            : date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    /// "14:32"
    static func time(from string: String) -> String {
        guard let date = date(from: string) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// Day-granularity key used to group entries into list sections.
    static func day(from string: String) -> Date? {
        date(from: string).map { Calendar.current.startOfDay(for: $0) }
    }

    /// "Сегодня" / "12 августа" — header for a day-grouped list section.
    static func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Сегодня" }
        if calendar.isDateInYesterday(day) { return "Вчера" }

        return isCurrentYear(day)
            ? day.formatted(.dateTime.day().month(.wide))
            : day.formatted(.dateTime.day().month(.wide).year())
    }

    private static func isCurrentYear(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.year, from: date) == calendar.component(.year, from: Date())
    }
}
