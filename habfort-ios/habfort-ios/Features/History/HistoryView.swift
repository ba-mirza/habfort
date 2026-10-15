import SwiftUI

struct HistoryView: View {
    @State private var viewModel = HistoryViewModel()
    @Environment(APIClient.self) private var apiClient

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AccentHeader {
                    AccentHeaderTitle(text: "История")
                    PeriodCard(
                        period: viewModel.period,
                        stats: viewModel.stats,
                        onChange: { period in
                            viewModel.period = period
                            Task { await viewModel.applyFilters(apiClient: apiClient) }
                        }
                    )
                }

                List {
                    listContent
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await viewModel.applyFilters(apiClient: apiClient) }
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.load(apiClient: apiClient) }
        }
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isLoading && viewModel.entries.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .cardRow(top: 16)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .cardRow(top: 16)
        } else if viewModel.entries.isEmpty {
            Text("За этот период ничего не выполнено.")
                .foregroundStyle(.secondary)
                .cardRow(top: 16)
        } else {
            ForEach(viewModel.dayGroups) { group in
                Section {
                    ForEach(group.entries) { entry in
                        HistoryEntryRowView(entry: entry)
                            .cardRow(top: 4)
                    }
                } header: {
                    Text(ISO8601.sectionTitle(for: group.day))
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color(.label))
                        .textCase(nil)
                        .padding(.top, 8)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                }
            }

            if viewModel.canLoadMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .cardRow()
                // Paging trigger: this row only exists while more pages are
                // expected, so reaching it means the user scrolled to the end.
                .task { await viewModel.loadMore(apiClient: apiClient) }
            }
        }
    }
}

/// Day / month / year switch, ‹ period › stepper and the period's totals.
private struct PeriodCard: View {
    let period: HistoryPeriod
    let stats: HistoryStats?
    let onChange: (HistoryPeriod) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Picker("Период", selection: Binding(
                get: { period.granularity },
                set: { granularity in
                    var next = period
                    next.granularity = granularity
                    next.anchor = Date()
                    onChange(next)
                }
            )) {
                ForEach(HistoryPeriod.Granularity.allCases) { granularity in
                    Text(granularity.displayName).tag(granularity)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                stepButton("chevron.left", enabled: true) { step(-1) }
                Spacer()
                Text(period.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                Spacer()
                stepButton("chevron.right", enabled: period.canGoForward) { step(1) }
            }

            HStack(spacing: 0) {
                total(value: "\(stats?.totalEntries ?? 0)", label: "выполнено")
                Divider().frame(height: 36)
                total(value: "\(stats?.totalCoinsAwarded ?? 0)", label: "жетонов", icon: "seal.fill")
            }
        }
        .padding(16)
        .card(bordered: false)
    }

    private func step(_ direction: Int) {
        var next = period
        next.step(direction)
        onChange(next)
    }

    private func stepButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(Color.secondary.opacity(0.12), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
        .accessibilityLabel(icon == "chevron.left" ? "Предыдущий период" : "Следующий период")
    }

    private func total(value: String, label: String, icon: String? = nil) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(Palette.yellow)
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
