import SwiftUI

/// Placeholder for a future paid tier — layout only, no purchases.
struct SubscriptionView: View {
    enum Plan: String, CaseIterable, Identifiable {
        case monthly, yearly
        var id: String { rawValue }
    }

    enum Tier: String, CaseIterable, Identifiable {
        case solo, family
        var id: String { rawValue }
        var title: String { self == .solo ? "Solo" : "Family" }
    }

    @State private var plan: Plan = .yearly
    @State private var tier: Tier = .solo

    // Illustrative prices for the preview.
    private var prices: (year: String, yearNote: String, month: String) {
        switch tier {
        case .solo: ("2 990 ₸", "249 ₸ в месяц · выгода 40%", "399 ₸")
        case .family: ("4 990 ₸", "До 5 человек · 416 ₸ в месяц", "699 ₸")
        }
    }

    private let perks: [(icon: String, title: String, detail: String)] = [
        ("person.3.fill", "Общие лобби", "Привычки и цели вместе с друзьями"),
        ("snowflake", "Заморозка серии", "Пропусти день и не потеряй стрик"),
        ("chart.xyaxis.line", "Расширенная статистика", "Тренды по каждой привычке"),
        ("paintpalette.fill", "Темы и иконки", "Оформи приложение под себя"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                hero

                Picker("Тариф", selection: $tier) {
                    ForEach(Tier.allCases) { tier in
                        Text(tier.title).tag(tier)
                    }
                }
                .pickerStyle(.segmented)

                if tier == .family {
                    Label("Один Pro на семью: до 5 участников, общая семейная лобби и общие цели.", systemImage: "person.3.sequence.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }

                VStack(spacing: 12) {
                    ForEach(perks, id: \.title) { perk in
                        HStack(spacing: 14) {
                            Image(systemName: perk.icon)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 38, height: 38)
                                .card(fill: Color.accentColor.opacity(0.14), radius: 11, bordered: false)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(perk.title).font(.body.weight(.semibold))
                                Text(perk.detail).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .card()

                VStack(spacing: 10) {
                    planCard(.yearly, title: "Год", price: prices.year, note: prices.yearNote)
                    planCard(.monthly, title: "Месяц", price: prices.month, note: "Отмена в любой момент")
                }

                Button {} label: {
                    Text("Оформить Pro \(tier.title)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(true)

                ComingSoonNote()
            }
            .padding(16)
        }
        .animation(.snappy, value: tier)
        .background(Color(.systemBackground))
        .navigationTitle("Beles Pro")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Palette.yellow)
            Text("Beles Pro")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Больше мотивации, больше способов держать серию.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(
            fill: LinearGradient(colors: [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.25, green: 0.16, blue: 0.10)], startPoint: .topLeading, endPoint: .bottomTrailing),
            radius: 22,
            bordered: false
        )
    }

    private func planCard(_ value: Plan, title: String, price: String, note: String) -> some View {
        let isSelected = plan == value
        return Button {
            withAnimation(.snappy) { plan = value }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(price)
                    .font(.system(.title3, design: .rounded, weight: .bold))
            }
            .padding(16)
            .card()
            .overlay {
                RoundedRectangle(cornerRadius: Palette.radius, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
}
