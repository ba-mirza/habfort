import SwiftUI

struct HabitsView: View {
    let viewModel: HabitsViewModel

    @Environment(APIClient.self) private var apiClient
    @State private var editingHabit: Habit?

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
            .sheet(item: $editingHabit) { habit in
                EditHabitView(habit: habit, habitsViewModel: viewModel)
            }
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
                HabitRowView(
                    habit: habit,
                    isPending: viewModel.pendingIds.contains(habit.id),
                    onToggle: { Task { await viewModel.toggleCompletion(habit, apiClient: apiClient) } }
                )
                .contentShape(Rectangle())
                .onTapGesture { editingHabit = habit }
                // A plain List draws a separator above its first row too,
                // which reads as a stray border under the title.
                .listRowSeparator(habit.id == viewModel.todaysHabits.first?.id ? .hidden : .visible, edges: .top)
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
}
