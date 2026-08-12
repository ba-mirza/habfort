import SwiftUI

struct MainTabView: View {
    enum AppTab: Hashable {
        case habits, rewards, history, create
    }

    @State private var selectedTab: AppTab = .habits
    @State private var habitsViewModel = HabitsViewModel()

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
    }
}
