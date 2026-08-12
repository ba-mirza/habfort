import SwiftUI

struct CreateHabitView: View {
    let habitsViewModel: HabitsViewModel
    @Binding var selectedTab: MainTabView.AppTab

    @Environment(APIClient.self) private var apiClient
    @State private var formViewModel = CreateHabitViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Привычка") {
                    TextField("Название", text: $formViewModel.name)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Тип")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ColoredChipPicker(
                            items: HabitType.allCases,
                            selection: $formViewModel.type,
                            icon: \.iconName,
                            label: \.displayName,
                            colors: \.chipColors
                        )
                    }
                    .listRowSeparator(.hidden)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Сложность")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ColoredChipPicker(
                            items: HabitDifficulty.allCases,
                            selection: $formViewModel.difficulty,
                            icon: \.iconName,
                            label: \.displayName,
                            colors: \.chipColors
                        )
                    }
                    .listRowSeparator(.hidden)
                }

                Section("Что начислится") {
                    HabitRewardInfoView(viewModel: formViewModel)
                }

                if formViewModel.type == .conditional {
                    Section("Длина челленджа") {
                        TextField("Количество дней", text: $formViewModel.requiredDaysText)
                            .keyboardType(.numberPad)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if formViewModel.type == .recurring {
                    Section("Расписание") {
                        Picker("Повтор", selection: $formViewModel.scheduleType) {
                            Text("Каждый день").tag(RecurringScheduleType.daily)
                            Text("Определённые дни").tag(RecurringScheduleType.daysOfWeek)
                        }
                        .pickerStyle(.segmented)

                        if formViewModel.scheduleType == .daysOfWeek {
                            DayOfWeekPicker(selection: $formViewModel.scheduleDays)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

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
                                Text("Создать привычку")
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
            .animation(.easeInOut(duration: 0.25), value: formViewModel.type)
            .navigationTitle("Создание")
            .task { await formViewModel.loadEconomy(apiClient: apiClient) }
        }
    }

    private func submit() async {
        let success = await formViewModel.submit(apiClient: apiClient)
        guard success else { return }
        await habitsViewModel.load(apiClient: apiClient)
        selectedTab = .habits
    }
}
