import SwiftUI

struct CreateRewardView: View {
    let rewardsViewModel: RewardsViewModel

    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss
    @State private var formViewModel = CreateRewardViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Награда") {
                    TextField("Название", text: $formViewModel.name)
                    TextField("Стоимость в жетонах", text: $formViewModel.costCoinsText)
                        .keyboardType(.numberPad)
                }

                Text("Минимум \(formViewModel.minCostCoins) жетонов — порог защищает от самообмана и не настраивается.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)

                if let errorMessage = formViewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        Group {
                            if formViewModel.isSubmitting {
                                ProgressView()
                            } else {
                                Text("Создать награду")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!formViewModel.isValid || formViewModel.isSubmitting)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Новая награда")
            .task { await formViewModel.loadEconomy(apiClient: apiClient) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        let success = await formViewModel.submit(apiClient: apiClient)
        guard success else { return }
        await rewardsViewModel.load(apiClient: apiClient)
        dismiss()
    }
}
