import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @Environment(APIClient.self) private var apiClient

    var body: some View {
        NavigationStack {
            HeaderSheetScreen(
                title: "История",
                onRefresh: { await viewModel.applyFilters(apiClient: apiClient) }
            ) {
                HistoryHeaderView(stats: viewModel.stats)
            } rows: {
                filters
                listContent
            }
            .task { await viewModel.load(apiClient: apiClient) }
        }
    }

    @ViewBuilder
    private var filters: some View {
        Picker(
            "Статус",
            selection: Binding(
                get: { viewModel.statusFilter },
                set: { newValue in
                    viewModel.statusFilter = newValue
                    Task { await viewModel.applyFilters(apiClient: apiClient) }
                }
            )
        ) {
            Text("Все").tag(HabitHistoryStatus?.none)
            ForEach(HabitHistoryStatus.allCases) { status in
                Text(status.displayName).tag(Optional(status))
            }
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)

        Picker(
            "Тип",
            selection: Binding(
                get: { viewModel.typeFilter },
                set: { newValue in
                    viewModel.typeFilter = newValue
                    Task { await viewModel.applyFilters(apiClient: apiClient) }
                }
            )
        ) {
            Text("Все").tag(HabitType?.none)
            ForEach(HabitType.allCases) { type in
                Text(type.displayName).tag(Optional(type))
            }
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isLoading && viewModel.entries.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        } else if viewModel.entries.isEmpty {
            Text("Пока нет записей в истории.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.dayGroups) { group in
                Section(ISO8601.sectionTitle(for: group.day)) {
                    ForEach(group.entries) { entry in
                        HistoryEntryRowView(entry: entry)
                    }
                }
            }

            if viewModel.canLoadMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                // Paging trigger: this row only exists while more pages are
                // expected, so reaching it means the user scrolled to the end.
                .task { await viewModel.loadMore(apiClient: apiClient) }
            }
        }
    }
}
