import SwiftUI

struct CreateHabitView: View {
    let habitsViewModel: HabitsViewModel
    @Binding var selectedTab: MainTabView.AppTab

    @Environment(APIClient.self) private var apiClient
    @State private var formViewModel = CreateHabitViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Name", text: $formViewModel.name)

                    Picker("Type", selection: $formViewModel.type) {
                        ForEach(HabitType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Difficulty", selection: $formViewModel.difficulty) {
                        ForEach(HabitDifficulty.allCases) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if formViewModel.type == .conditional {
                    Section("Streak length") {
                        TextField("Required days", text: $formViewModel.requiredDaysText)
                            .keyboardType(.numberPad)
                    }
                }

                if formViewModel.type == .recurring {
                    Section("Schedule") {
                        Picker("Repeats", selection: $formViewModel.scheduleType) {
                            Text("Every day").tag(RecurringScheduleType.daily)
                            Text("Specific days").tag(RecurringScheduleType.daysOfWeek)
                        }
                        .pickerStyle(.segmented)

                        if formViewModel.scheduleType == .daysOfWeek {
                            DayOfWeekPicker(selection: $formViewModel.scheduleDays)
                        }
                    }
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
                        if formViewModel.isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Habit")
                        }
                    }
                    .disabled(!formViewModel.isValid || formViewModel.isSubmitting)
                }
            }
            .navigationTitle("Create")
        }
    }

    private func submit() async {
        let success = await formViewModel.submit(apiClient: apiClient)
        guard success else { return }
        await habitsViewModel.load(apiClient: apiClient)
        selectedTab = .habits
    }
}
