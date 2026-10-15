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
    @Environment(APIClient.self) private var apiClient

    var body: some View {
        #if DEBUG
        // `-initialTab profile|invite|pro` opens that pushed screen on its own.
        switch UserDefaults.standard.string(forKey: "initialTab") {
        case "profile": NavigationStack { SettingsView() }
        case "invite": NavigationStack { InviteFriendsView() }
        case "pro": NavigationStack { SubscriptionView() }
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
            if let me: Me = try? await apiClient.get("/me"), me.onboardedAt == nil {
                showOnboarding = true
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
