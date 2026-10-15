import SwiftUI

struct MainTabView: View {
    enum AppTab: String, Hashable {
        case habits, rewards, history, create
    }

    @State private var selectedTab: AppTab = Self.initialTab

    /// Debug builds can open on another tab with `-initialTab rewards` (launch
    /// arguments land in UserDefaults) — handy for checking a screen in the
    /// Simulator without tapping through.
    private static var initialTab: AppTab {
        #if DEBUG
        UserDefaults.standard.string(forKey: "initialTab").flatMap(AppTab.init(rawValue:)) ?? .habits
        #else
        .habits
        #endif
    }
    @State private var habitsViewModel = HabitsViewModel()
    @State private var showOnboarding = false
    @State private var showCountryPrompt = false
    private static let countryPromptKey = "countryPromptShown"
    @Environment(APIClient.self) private var apiClient

    var body: some View {
        #if DEBUG
        // `-initialTab profile|invite|pro|login|signup|country` opens that screen on its own.
        switch UserDefaults.standard.string(forKey: "initialTab") {
        case "profile": NavigationStack { ProfileView() }
        case "invite": NavigationStack { InviteFriendsView() }
        case "pro": NavigationStack { SubscriptionView() }
        case "login", "signup": AuthFlowView()
        case "country": NavigationStack { CountrySettingView(initial: nil, showsSkip: true) { _ in } }
        default: tabs
        }
        #else
        tabs
        #endif
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            HabitsView(viewModel: habitsViewModel)
                .tabItem { Label("Привычки", systemImage: "checklist") }
                .tag(AppTab.habits)

            RewardsView()
                .tabItem { Label("Награды", systemImage: "gift") }
                .tag(AppTab.rewards)

            HistoryView()
                .tabItem { Label("История", systemImage: "clock") }
                .tag(AppTab.history)

            CreateHabitView(habitsViewModel: habitsViewModel, selectedTab: $selectedTab)
                .tabItem { Label("Создать", systemImage: "plus.circle") }
                .tag(AppTab.create)
        }
        .task {
            // Only a confirmed "not onboarded" opens the flow — a failed
            // request must not push existing users through it again.
            guard let me: Me = try? await apiClient.get("/me") else { return }
            if me.onboardedAt == nil {
                showOnboarding = true
            } else if me.country == nil, !UserDefaults.standard.bool(forKey: Self.countryPromptKey) {
                // Accounts from before the onboarding asked for a country get
                // asked once; "Позже" leaves it to Settings.
                UserDefaults.standard.set(true, forKey: Self.countryPromptKey)
                showCountryPrompt = true
            }
        }
        .sheet(isPresented: $showCountryPrompt) {
            NavigationStack {
                CountrySettingView(initial: nil, showsSkip: true) { _ in }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
                Task { await habitsViewModel.load(apiClient: apiClient) }
            }
        }
    }
}
