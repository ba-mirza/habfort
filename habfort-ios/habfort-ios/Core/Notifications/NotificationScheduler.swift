import Foundation
import UserNotifications

/// Local notifications only — nothing here needs a server or APNs. The rules
/// keep them rare: permission is asked only after the first completed habit
/// (people who've felt the loop say yes far more often), and the only
/// scheduled reminder fires at most once and only for someone who stopped
/// opening the app.
enum NotificationScheduler {
    private static let askedKey = "notifications.permissionAsked"
    private static let dormantId = "reminder.dormant"
    /// An active user always pushes the reminder at least this far out, so
    /// it only ever reaches someone who's been away.
    private static let minimumQuietDays = 3
    private static let reminderHour = 10

    /// Asks once, after the user's first completed habit.
    static func requestPermissionAfterFirstCompletion() async {
        guard !UserDefaults.standard.bool(forKey: askedKey) else { return }
        UserDefaults.standard.set(true, forKey: askedKey)
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Re-planned on every successful load, so it keeps sliding forward while
    /// the app is in use: the next Monday or 1st of the month (fresh-start
    /// days) at 10:00, at least `minimumQuietDays` away.
    static func rescheduleDormantReminder(goal: Reward?, balance: Int) async {
        let center = UNUserNotificationCenter.current()
        guard await center.notificationSettings().authorizationStatus == .authorized,
              let fireDate = nextFreshStart(after: Date())
        else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = "Новый старт"
        if let goal, goal.costCoins > balance {
            content.body = "До «\(goal.name)» осталось \(goal.costCoins - balance) жетонов. Одна привычка сегодня — и ты ближе."
        } else if let goal {
            content.body = "Жетонов уже хватает на «\(goal.name)». Загляни и забери награду!"
        } else {
            content.body = "Хороший день, чтобы вернуться к привычкам."
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let request = UNNotificationRequest(
            identifier: dormantId,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        // Same identifier replaces the pending one — there's only ever one.
        try? await center.add(request)
    }

    static func nextFreshStart(after now: Date) -> Date? {
        let calendar = Calendar.current
        guard let earliest = calendar.date(byAdding: .day, value: minimumQuietDays, to: calendar.startOfDay(for: now))
        else { return nil }
        for offset in 0..<40 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: earliest) else { continue }
            let isMonday = calendar.component(.weekday, from: day) == 2
            let isFirst = calendar.component(.day, from: day) == 1
            if isMonday || isFirst {
                return calendar.date(bySettingHour: reminderHour, minute: 0, second: 0, of: day)
            }
        }
        return nil
    }
}
