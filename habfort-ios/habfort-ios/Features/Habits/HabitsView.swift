import SwiftUI

struct HabitsView: View {
    let viewModel: HabitsViewModel

    @Environment(APIClient.self) private var apiClient

    var body: some View {
        NavigationStack {
            HeaderSheetScreen(
                title: "Мои привычки",
                onRefresh: { await viewModel.load(apiClient: apiClient) }
            ) {
                ProfileWidgetView(walletBalance: viewModel.walletBalance)
            } rows: {
                listContent
            }
            .task { await viewModel.load(apiClient: apiClient) }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isLoading && viewModel.habits.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        } else if viewModel.todaysHabits.isEmpty {
            Text(viewModel.habits.isEmpty ? "Пока нет привычек." : "На сегодня ничего не запланировано.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.todaysHabits) { habit in
                HabitRowView(habit: habit)
                    // A plain List draws a separator above its first row too,
                    // which reads as a stray border under the title.
                    .listRowSeparator(habit.id == viewModel.todaysHabits.first?.id ? .hidden : .visible, edges: .top)
                    .swipeActions(edge: .leading) {
                        Button {
                            Task { await toggleCompletion(habit) }
                        } label: {
                            Label(
                                habit.isCompletedToday == true ? "Отменить" : "Выполнить",
                                systemImage: habit.isCompletedToday == true ? "arrow.uturn.left" : "checkmark"
                            )
                        }
                        .tint(habit.isCompletedToday == true ? .gray : .green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await viewModel.delete(habit, apiClient: apiClient) }
                        } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
            }
        }
    }

    private func toggleCompletion(_ habit: Habit) async {
        switch habit.type {
        case .instant:
            await viewModel.complete(habit, apiClient: apiClient)
        case .conditional, .recurring:
            await viewModel.log(habit, completed: !(habit.isCompletedToday ?? false), apiClient: apiClient)
        }
    }
}
