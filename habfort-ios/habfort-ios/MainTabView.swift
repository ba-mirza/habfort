import SwiftUI

struct MainTabView: View {
    enum AppTab: Hashable {
        case habits, rewards, history, create
    }

    @State private var selectedTab: AppTab = .habits
    @State private var habitsViewModel = HabitsViewModel()
    @State private var showOnboarding = false
    @Environment(APIClient.self) private var apiClient

    var body: some View {
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
