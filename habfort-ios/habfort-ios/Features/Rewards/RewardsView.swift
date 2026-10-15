import SwiftUI

struct RewardsView: View {
    @State private var viewModel = RewardsViewModel()
    @State private var isShowingCreateReward = false
    @State private var rewardPendingRedeem: Reward?
    @State private var editingRedeem: Redeem?
    /// Picked on the celebration screen; opened once that cover is gone —
    /// presenting a sheet while a full-screen cover dismisses is dropped.
    @State private var redeemToEditAfterCelebration: Redeem?

    @Environment(APIClient.self) private var apiClient

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AccentHeader {
                    HStack {
                        AccentHeaderTitle(text: "Награды")
                        Spacer()
                        Button {
                            isShowingCreateReward = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.black)
                                .frame(width: 40, height: 40)
                                .background(.white, in: Circle())
                        }
                        .accessibilityLabel("Новая награда")
                    }
                    BalanceCard(balance: viewModel.walletBalance, spentTotal: viewModel.spentTotal)
                }

                List {
                    Picker("Раздел", selection: $viewModel.section) {
                        ForEach(RewardsViewModel.Section.allCases) { section in
                            Text(section.displayName).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .cardRow(top: 16)

                    listContent
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable { await viewModel.load(apiClient: apiClient) }
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
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
            .fullScreenCover(item: $viewModel.celebration, onDismiss: {
                editingRedeem = redeemToEditAfterCelebration
                redeemToEditAfterCelebration = nil
            }) { celebration in
                RedeemCelebrationView(celebration: celebration) {
                    viewModel.celebration = nil
                } onAddPhoto: {
                    redeemToEditAfterCelebration = celebration.redeem
                    viewModel.celebration = nil
                }
            }
            .sheet(item: $editingRedeem) { redeem in
                RedeemDiaryEditor(redeem: redeem) {
                    await viewModel.load(apiClient: apiClient)
                }
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
            .cardRow()
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .cardRow()
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
                .cardRow()
        } else {
            ForEach(viewModel.rewards) { reward in
                RewardRowView(
                    reward: reward,
                    balance: viewModel.walletBalance,
                    onRedeem: { rewardPendingRedeem = reward }
                )
                .cardRow()
                .swipeActions(edge: .leading) {
                    Button {
                        Task { await viewModel.toggleGoal(reward, apiClient: apiClient) }
                    } label: {
                        Label(reward.isGoal == true ? "Убрать цель" : "Сделать целью",
                              systemImage: reward.isGoal == true ? "star.slash" : "star.fill")
                    }
                    .tint(.yellow)
                }
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
                .cardRow()
        } else {
            ForEach(viewModel.archivedRewards) { reward in
                ArchivedRewardRowView(reward: reward) {
                    Task { await viewModel.restore(reward, apiClient: apiClient) }
                }
                .cardRow()
            }
        }
    }

    @ViewBuilder
    private var redeemRows: some View {
        if viewModel.redeems.isEmpty {
            Text("Пока ничего не потрачено.")
                .foregroundStyle(.secondary)
                .cardRow()
        } else {
            ForEach(viewModel.redeems) { redeem in
                RedeemRowView(redeem: redeem)
                    .onTapGesture { editingRedeem = redeem }
                    .cardRow()
            }
        }
    }
}

/// Balance on the accent header — the number that decides what's affordable.
private struct BalanceCard: View {
    let balance: Int
    let spentTotal: Int

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Доступно")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text("\(balance)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .contentTransition(.numericText(value: Double(balance)))
                    Image(systemName: "seal.fill")
                        .font(.title3)
                        .foregroundStyle(Palette.yellow)
                }
            }
            Spacer()
            if spentTotal > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Потрачено")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(spentTotal)")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                }
            }
        }
        .padding(16)
        .card(bordered: false)
    }
}
