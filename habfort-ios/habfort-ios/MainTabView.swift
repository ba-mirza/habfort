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
                .tabItem { Label("Habits", systemImage: "checklist") }
                .tag(AppTab.habits)

            Text("Rewards — Phase 5")
                .tabItem { Label("Rewards", systemImage: "gift") }
                .tag(AppTab.rewards)

            Text("History — Phase 6")
                .tabItem { Label("History", systemImage: "clock") }
                .tag(AppTab.history)

            CreateHabitView(habitsViewModel: habitsViewModel, selectedTab: $selectedTab)
                .tabItem { Label("Create", systemImage: "plus.circle") }
                .tag(AppTab.create)
        }
    }
}
