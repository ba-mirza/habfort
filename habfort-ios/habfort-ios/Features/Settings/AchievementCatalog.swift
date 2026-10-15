import SwiftUI

/// Client-side names and icons for the achievement ids the backend reports.
/// Unknown ids (a newer backend) still show, with a generic badge.
enum AchievementCatalog {
    struct Entry {
        let title: String
        let detail: String
        let icon: String
        let color: Color
    }

    static func entry(for id: String) -> Entry {
        switch id {
        case "first_step": Entry(title: "Первый шаг", detail: "Выполни первую привычку", icon: "figure.walk", color: Palette.teal)
        case "week_streak": Entry(title: "Неделя в огне", detail: "7 дней подряд", icon: "flame.fill", color: .orange)
        case "month_streak": Entry(title: "Железная воля", detail: "30 дней подряд", icon: "bolt.shield.fill", color: Palette.red)
        case "hundred": Entry(title: "Сотня", detail: "100 выполнений", icon: "100.circle.fill", color: Palette.purple)
        case "first_reward": Entry(title: "Заслужил", detail: "Получи первую награду", icon: "gift.fill", color: Palette.yellow)
        case "challenger": Entry(title: "Челленджер", detail: "Пройди челлендж до конца", icon: "trophy.fill", color: Palette.purple)
        case "perfect_day": Entry(title: "Идеальный день", detail: "Закрой все привычки дня", icon: "sparkles", color: Palette.green)
        case "piggy_bank": Entry(title: "Копилка", detail: "Заработай 1000 жетонов", icon: "seal.fill", color: Palette.yellow)
        default: Entry(title: "Достижение", detail: "", icon: "star.fill", color: .accentColor)
        }
    }
}
