import SwiftUI

/// Placeholder for the paid tier — layout only, no purchases. Prices are the
/// planned ones but nothing is wired to StoreKit yet.
struct SubscriptionView: View {
    enum Tier: String, CaseIterable, Identifiable {
        case solo, family
        var id: String { rawValue }
        var title: String { self == .solo ? "Solo" : "Family" }
    }

    enum Billing { case monthly, yearly }

    private struct Pricing {
        let monthly: Int
        let yearly: Int
        var yearlyFull: Int { monthly * 12 }
        var savingPercent: Int { Int((1 - Double(yearly) / Double(yearlyFull)) * 100) }
    }

    @State private var tier: Tier = .solo
    @State private var billing: Billing = .yearly

    private var pricing: Pricing {
        switch tier {
        case .solo: Pricing(monthly: 690, yearly: 5_990)
        case .family: Pricing(monthly: 1_190, yearly: 9_990)
        }
    }

    private var perks: [(icon: String, text: String)] {
        var perks: [(String, String)] = [
            ("person.3.fill", "Общие лобби и цели с друзьями"),
            ("snowflake", "Заморозка серии — пропуск без потери стрика"),
            ("chart.xyaxis.line", "Расширенная статистика по привычкам"),
            ("paintpalette.fill", "Темы и иконки приложения"),
        ]
        if tier == .family {
            perks.insert(("figure.2.and.child.holdinghands", "До 5 участников на одной подписке"), at: 0)
        }
        return perks
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                hero

                Picker("Тариф", selection: $tier) {
                    ForEach(Tier.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(spacing: 14) {
                    planCard(
                        .monthly,
                        band: "ЕЖЕМЕСЯЧНО",
                        price: "\(format(pricing.monthly)) ₸",
                        period: "/мес",
                        oldPrice: nil,
                        note: tier == .solo ? "Можно отменить в любой момент" : "Для всей семьи, отмена в любой момент"
                    )
                    planCard(
                        .yearly,
                        band: "ЕЖЕГОДНО — ВЫГОДА \(pricing.savingPercent)%",
                        price: "\(format(pricing.yearly)) ₸",
                        period: "/год",
                        oldPrice: "\(format(pricing.yearlyFull)) ₸",
                        note: "\(format(pricing.yearly / 12)) ₸ в месяц"
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(perks, id: \.text) { perk in
                        Label {
                            Text(perk.text).font(.subheadline)
                        } icon: {
                            Image(systemName: perk.icon)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 26)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .card()

                Button {} label: {
                    Text("Оформить Pro \(tier.title)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(true)

                ComingSoonNote()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .animation(.snappy, value: tier)
            .animation(.snappy, value: billing)
        }
        .background(alignment: .top) {
            LinearGradient(colors: [Color.accentColor.opacity(0.22), Color(.systemBackground)], startPoint: .top, endPoint: .bottom)
                .frame(height: 420)
                .ignoresSafeArea(edges: .top)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Beles Pro")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            ShiningCrown()
                .frame(height: 150)
            Text("Beles Pro")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text(tier == .solo
                 ? "Больше мотивации и способов держать серию."
                 : "Одна подписка на всю семью — привычки и цели вместе.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
        }
        .padding(.top, 8)
    }

    /// Plan option in the reference's style: a label band on top, the price
    /// card inside it; the selected plan's band turns orange.
    private func planCard(_ value: Billing, band: String, price: String, period: String, oldPrice: String?, note: String) -> some View {
        let isSelected = billing == value
        return Button {
            billing = value
        } label: {
            VStack(spacing: 0) {
                Text(band)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .secondary)
                    .padding(.vertical, 8)
                HStack(spacing: 14) {
                    ZStack {
                        Circle().stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.4), lineWidth: 2)
                        if isSelected {
                            Circle().fill(Color.accentColor).padding(5)
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 26, height: 26)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            if let oldPrice {
                                Text(oldPrice)
                                    .strikethrough()
                                    .foregroundStyle(.secondary)
                            }
                            Text(price)
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            + Text(period)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding([.horizontal, .bottom], 4)
            }
            .background(
                isSelected ? Color.accentColor : Color.secondary.opacity(0.14),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func format(_ amount: Int) -> String {
        amount.formatted(.number.grouping(.automatic).locale(ISO8601.russian))
    }
}

/// A big crown in a laurel wreath with a light sweep running across it.
private struct ShiningCrown: View {
    @State private var shine: CGFloat = -1
    @State private var floating = false

    var body: some View {
        HStack(spacing: -6) {
            Image(systemName: "laurel.leading")
            Image(systemName: "crown.fill")
                .font(.system(size: 76, weight: .semibold))
                .offset(y: floating ? -4 : 2)
            Image(systemName: "laurel.trailing")
        }
        .font(.system(size: 92, weight: .regular))
        .foregroundStyle(
            LinearGradient(colors: [Palette.yellow, .accentColor], startPoint: .top, endPoint: .bottom)
        )
        .overlay {
            GeometryReader { proxy in
                LinearGradient(colors: [.clear, .white.opacity(0.85), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: proxy.size.width * 0.35)
                    .rotationEffect(.degrees(20))
                    .offset(x: shine * proxy.size.width)
            }
            .mask {
                HStack(spacing: -6) {
                    Image(systemName: "laurel.leading")
                    Image(systemName: "crown.fill")
                        .font(.system(size: 76, weight: .semibold))
                        .offset(y: floating ? -4 : 2)
                    Image(systemName: "laurel.trailing")
                }
                .font(.system(size: 92, weight: .regular))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).delay(0.4).repeatForever(autoreverses: false)) {
                shine = 1.2
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                floating = true
            }
        }
        .accessibilityHidden(true)
    }
}
