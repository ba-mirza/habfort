import Foundation

/// A country by ISO 3166-1 alpha-2 code, with its Russian name and flag.
struct Country: Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }

    /// Regional-indicator flag emoji built from the two letters.
    var flag: String {
        code.unicodeScalars
            .compactMap { UnicodeScalar(127_397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    static func named(_ code: String) -> Country? {
        guard let name = ISO8601.russian.localizedString(forRegionCode: code) else { return nil }
        return Country(code: code, name: name)
    }

    /// Two-letter region codes that aren't countries: island groups and
    /// territories with their own code (Canary Islands, Ceuta…), the EU and
    /// UN, pseudo-locales.
    private static let nonCountryCodes: Set<String> = [
        "AC", "CP", "DG", "EA", "EU", "EZ", "IC", "QO", "TA", "UN", "XA", "XB",
    ]

    /// Every country the system knows, sorted by Russian name.
    static let all: [Country] = Locale.Region.isoRegions
        .map(\.identifier)
        .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) && !nonCountryCodes.contains($0) }
        .compactMap(named)
        .sorted { $0.name.compare($1.name, locale: ISO8601.russian) == .orderedAscending }

    /// The device's region — no location permission needed, and right for
    /// nearly everyone.
    static var deviceCountry: Country? {
        Locale.current.region.map(\.identifier).flatMap(named)
    }
}
