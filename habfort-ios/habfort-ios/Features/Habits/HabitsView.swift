import SwiftUI

struct HabitsView: View {
    let viewModel: HabitsViewModel

    @Environment(APIClient.self) private var apiClient

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ProfileWidgetView()
                }

                Section {
                    FilterWidgetView(
                        typeFilter: Binding(
                            get: { viewModel.typeFilter },
                            set: { viewModel.typeFilter = $0 }
                        ),
                        difficultyFilter: Binding(
                            get: { viewModel.difficultyFilter },
                            set: { viewModel.difficultyFilter = $0 }
                        )
                    )
                }

                Section {
                    listContent
                }
            }
            .navigationTitle("Habits")
            .refreshable { await viewModel.load(apiClient: apiClient) }
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
        } else if viewModel.filteredHabits.isEmpty {
            Text(viewModel.habits.isEmpty ? "No habits yet." : "No habits match these filters.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.filteredHabits) { habit in
                HabitRowView(habit: habit)
            }
        }
    }
}
