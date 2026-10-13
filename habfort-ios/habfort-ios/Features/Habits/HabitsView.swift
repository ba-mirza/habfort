import SwiftUI

struct HabitsView: View {
    let viewModel: HabitsViewModel

    @Environment(APIClient.self) private var apiClient
    @State private var editingHabit: Habit?
    @State private var selectedDay = Date()

    private var isTodaySelected: Bool {
        Calendar.current.isDateInToday(selectedDay)
    }

    var body: some View {
        NavigationStack {
            HeaderSheetScreen(
                title: isTodaySelected ? "Мои привычки" : ISO8601.sectionTitle(for: selectedDay),
                onRefresh: { await viewModel.load(apiClient: apiClient) }
            ) {
                ProfileWidgetView(walletBalance: viewModel.walletBalance, goal: viewModel.goal)
            } rows: {
                // A plain List pins section headers, so the strip stays on top
                // of the list while it scrolls.
                Section {
                    if isTodaySelected {
                        listContent
                    } else {
                        otherDayContent
                    }
                } header: {
                    WeekStripView(
                        days: WeekCalendar.days(),
                        selectedDay: $selectedDay,
                        hasCompletions: viewModel.hasCompletions(on:)
                    )
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .background(Color(.systemBackground))
                }
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

    @ViewBuilder
    private var otherDayContent: some View {
        let entries = viewModel.entries(for: selectedDay)
        if entries.isEmpty {
            Text(selectedDay > Date() ? "На этот день ничего не запланировано." : "В этот день ничего не было.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(entries) { entry in
                DayHabitRowView(entry: entry)
                    .listRowSeparator(entry.id == entries.first?.id ? .hidden : .visible, edges: .top)
            }
        }
    }
}
