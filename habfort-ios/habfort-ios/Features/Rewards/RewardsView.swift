import SwiftUI

struct RewardsView: View {
    @State private var viewModel = RewardsViewModel()
    @State private var isShowingCreateReward = false
    @State private var rewardPendingRedeem: Reward?

    @Environment(APIClient.self) private var apiClient

    var body: some View {
        NavigationStack {
            HeaderSheetScreen(
                title: viewModel.section.displayName,
                onRefresh: { await viewModel.load(apiClient: apiClient) }
            ) {
                RewardsHeaderView(
                    walletBalance: viewModel.walletBalance,
                    spentTotal: viewModel.spentTotal
                )
            } accessory: {
                Button {
                    isShowingCreateReward = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                }
            } rows: {
                Picker("Раздел", selection: $viewModel.section) {
                    ForEach(RewardsViewModel.Section.allCases) { section in
                        Text(section.displayName).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                listContent
            }
            .sheet(isPresented: $isShowingCreateReward) {
                CreateRewardView(rewardsViewModel: viewModel)
            }
            .confirmationDialog(
                confirmationTitle,
                isPresented: Binding(
                    get: { rewardPendingRedeem != nil },
                    set: { if !$0 { rewardPendingRedeem = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Потратить") {
                    if let reward = rewardPendingRedeem {
                        Task { await viewModel.redeem(reward, apiClient: apiClient) }
                    }
                }
                Button("Отмена", role: .cancel) {}
            }
            .alert(
                "Не получилось",
                isPresented: Binding(
                    get: { viewModel.actionErrorMessage != nil },
                    set: { if !$0 { viewModel.actionErrorMessage = nil } }
                )
            ) {
                Button("Ок", role: .cancel) {}
            } message: {
                Text(viewModel.actionErrorMessage ?? "")
            }
            .task { await viewModel.load(apiClient: apiClient) }
        }
    }

    private var confirmationTitle: String {
        guard let reward = rewardPendingRedeem else { return "" }
        return "Потратить \(reward.costCoins) жетонов на «\(reward.name)»?"
    }

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isLoading && viewModel.rewards.isEmpty && viewModel.redeems.isEmpty
            && viewModel.archivedRewards.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        } else {
            switch viewModel.section {
            case .rewards: rewardRows
            case .redeems: redeemRows
            case .archive: archivedRows
            }
        }
    }

    @ViewBuilder
    private var rewardRows: some View {
        if viewModel.rewards.isEmpty {
            Text("Пока нет наград. Добавь первую через +.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.rewards) { reward in
                RewardRowView(
                    reward: reward,
                    canAfford: viewModel.canAfford(reward),
                    missingCoins: viewModel.missingCoins(for: reward),
                    onRedeem: { rewardPendingRedeem = reward }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await viewModel.archive(reward, apiClient: apiClient) }
                    } label: {
                        Label("В архив", systemImage: "archivebox")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var archivedRows: some View {
        if viewModel.archivedRewards.isEmpty {
            Text("Архив пуст.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.archivedRewards) { reward in
                ArchivedRewardRowView(reward: reward) {
                    Task { await viewModel.restore(reward, apiClient: apiClient) }
                }
            }
        }
    }

    @ViewBuilder
    private var redeemRows: some View {
        if viewModel.redeems.isEmpty {
            Text("Пока ничего не потрачено.")
                .foregroundStyle(.secondary)
        } else {
            ForEach(viewModel.redeems) { redeem in
                RedeemRowView(redeem: redeem)
            }
        }
    }
}
