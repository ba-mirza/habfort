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
            VStack(spacing: 0) {
                HabitsHeaderView(balance: viewModel.walletBalance, goal: viewModel.goal)

                List {
                    StatTilesView(
                        streak: viewModel.streak,
                        doneToday: viewModel.todaysDoneCount,
                        dueToday: viewModel.todaysHabits.count,
                        activeCount: viewModel.habits.count
                    )
                    .cardRow(top: 16)

                    // A plain List pins section headers, so the strip stays on
                    // top of the list while it scrolls.
                    Section {
                        if isTodaySelected {
                            listContent
                        } else {
                            otherDayContent
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(isTodaySelected ? "Мои привычки" : ISO8601.sectionTitle(for: selectedDay))
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                // Plain-list headers render secondary by default.
                                .foregroundStyle(Color(.label))
                            WeekStripView(
                                days: WeekCalendar.days(),
                                selectedDay: $selectedDay,
                                doneDays: Set(
                                    WeekCalendar.days()
                                        .filter(viewModel.hasCompletions(on:))
                                        .map(WeekCalendar.calendar.startOfDay(for:))
                                )
                            )
                        }
                        .textCase(nil)
                        .padding(.vertical, 10)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await viewModel.load(apiClient: apiClient) }
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.load(apiClient: apiClient) }
            .overlay(alignment: .top) {
                if let milestone = viewModel.milestone {
                    GoalMilestoneBanner(milestone: milestone)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { viewModel.milestone = nil }
                        .task(id: milestone.id) {
                            try? await Task.sleep(for: .seconds(4))
                            viewModel.milestone = nil
                        }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.milestone)
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
            .cardRow()
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .cardRow()
        } else if viewModel.todaysHabits.isEmpty {
            Text(viewModel.habits.isEmpty ? "Пока нет привычек." : "На сегодня ничего не запланировано.")
                .foregroundStyle(.secondary)
                .cardRow()
        } else {
            ForEach(viewModel.todaysHabits) { habit in
                HabitRowView(
                    habit: habit,
                    reward: viewModel.reward(for: habit),
                    isPending: viewModel.pendingIds.contains(habit.id),
                    onToggle: { Task { await viewModel.toggleCompletion(habit, apiClient: apiClient) } }
                )
                .cardRow()
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.delete(habit, apiClient: apiClient) }
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    Button {
                        editingHabit = habit
                    } label: {
                        Label("Изменить", systemImage: "pencil")
                    }
                    .tint(.gray)
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
                .cardRow()
        } else {
            ForEach(entries) { entry in
                DayHabitRowView(entry: entry)
                    .cardRow()
            }
        }
    }
}

private extension View {
    /// A card sitting in the plain List: no separators, no row background,
    /// side margins plus room for the card's offset shadow.
    func cardRow(top: CGFloat = 6) -> some View {
        self
            .listRowInsets(EdgeInsets(top: top, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
