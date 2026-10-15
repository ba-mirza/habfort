import Foundation

/// Russian noun form for a count: 1 день, 2 дня, 5 дней (11–14 take "many").
func russianPlural(_ n: Int, one: String, few: String, many: String) -> String {
    let mod10 = n % 10, mod100 = n % 100
    if mod10 == 1 && mod100 != 11 { return one }
    if (2...4).contains(mod10) && !(12...14).contains(mod100) { return few }
    return many
}
