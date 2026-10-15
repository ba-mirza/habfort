import Auth
import SwiftUI

/// Profile: level and XP, headline stats, achievements, activity heatmap,
/// then app settings.
struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(APIClient.self) private var apiClient
    @State private var viewModel = ProfileViewModel()
    @State private var activityViewModel = ActivityViewModel()
    @State private var selectedAchievement: String?
    @State private var destination: Destination?

    /// Pushed screens. Driven by state rather than NavigationLinks: several
    /// links inside one List row all fire together, and List adds its own
    /// chevron next to ours.
    enum Destination: Hashable {
        case pro, invite
    }
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var name: String {
        let email = authManager.session?.user.email ?? ""
        return email.split(separator: "@").first.map(String.init) ?? "Аккаунт"
    }

    private var theme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue }
        )
    }

    private let tileColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let badgeColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        List {
            ProfileHeader(
                name: name,
                publicId: viewModel.me?.publicId,
                progress: viewModel.progress,
                onOpenPro: { destination = .pro }
            )
            .cardRow(top: 8)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .cardRow()
            }

            LazyVGrid(columns: tileColumns, spacing: 12) {
                StatTile(value: "\(viewModel.streak?.current ?? 0)", label: russianPlural(viewModel.streak?.current ?? 0, one: "день подряд", few: "дня подряд", many: "дней подряд"), icon: "flame.fill", color: Palette.purple)
                StatTile(value: "\(viewModel.streak?.best ?? 0)", label: "лучшая серия", icon: "crown.fill", color: .accentColor)
                StatTile(value: rateText, label: "выполнение за 30 дней", icon: "chart.bar.fill", color: Palette.teal)
                StatTile(value: "\(viewModel.progress?.metrics.completions ?? 0)", label: "выполнено всего", icon: "checkmark.circle.fill", color: Palette.green)
                StatTile(value: "\(viewModel.progress?.metrics.coinsEarned ?? 0)", label: "жетонов заработано", icon: "seal.fill", color: Color(red: 0.85, green: 0.6, blue: 0.1))
                StatTile(value: "\(viewModel.progress?.metrics.redeems ?? 0)", label: "наград получено", icon: "gift.fill", color: Palette.red)
            }
            .cardRow(top: 10)

            Button { destination = .pro } label: {
                linkRow(icon: "crown.fill", color: Palette.yellow, title: "Beles Pro", subtitle: "Solo и Family — лобби, заморозка серии")
            }
            .buttonStyle(.plain)
            .cardRow(top: 20)

            Button { destination = .invite } label: {
                linkRow(icon: "person.2.fill", color: Palette.purple, title: "Пригласить друзей", subtitle: "Привычки вместе — скоро")
            }
            .buttonStyle(.plain)
            .cardRow()

            section(title: "Достижения", trailing: achievementsCount) {
                VStack(spacing: 12) {
                    LazyVGrid(columns: badgeColumns, spacing: 16) {
                        ForEach(viewModel.progress?.achievements ?? []) { achievement in
                            AchievementBadge(achievement: achievement)
                                .onTapGesture {
                                    selectedAchievement = selectedAchievement == achievement.id ? nil : achievement.id
                                }
                        }
                    }
                    if let id = selectedAchievement {
                        Text(AchievementCatalog.entry(for: id).detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .transition(.opacity)
                    }
                }
                .animation(.snappy, value: selectedAchievement)
                .padding(16)
                .card()
            }

            section(title: "Активность") {
                ActivitySectionView(viewModel: activityViewModel)
                    .padding(16)
                    .card()
            }

            section(title: "Тема") {
                Picker("Тема", selection: theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.displayName, systemImage: theme.iconName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button(role: .destructive) {
                Task { try? await authManager.signOut() }
            } label: {
                Text("Выйти")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.red)
            .cardRow(top: 24)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .pro: SubscriptionView()
            case .invite: InviteFriendsView()
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    private var rateText: String {
        guard let rate = viewModel.discipline?.rate else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }

    private var achievementsCount: String? {
        guard let achievements = viewModel.progress?.achievements else { return nil }
        return "\(achievements.filter(\.unlocked).count) из \(achievements.count)"
    }

    private func linkRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .card(fill: color, radius: 11, bordered: false)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .card()
        .contentShape(Rectangle())
    }

    private func section(title: String, trailing: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            content()
        }
        .cardRow(top: 20)
    }

    private func load() async {
        async let profile: Void = viewModel.load(apiClient: apiClient)
        async let activity: Void = activityViewModel.load(apiClient: apiClient)
        _ = await (profile, activity)
    }
}
