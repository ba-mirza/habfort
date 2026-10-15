import SwiftUI

/// Edits apply to the future only — past completions keep what they earned.
/// Type and challenge length are fixed at creation, and so is a challenge's
/// difficulty (it pays out once for the whole streak), mirroring the backend.
struct EditHabitView: View {
    let habit: Habit
    let habitsViewModel: HabitsViewModel

    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var difficulty: HabitDifficulty
    @State private var scheduleType: RecurringScheduleType
    @State private var scheduleDays: Set<Int>
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(habit: Habit, habitsViewModel: HabitsViewModel) {
        self.habit = habit
        self.habitsViewModel = habitsViewModel
        _name = State(initialValue: habit.name)
        _difficulty = State(initialValue: habit.difficulty)
        _scheduleType = State(initialValue: habit.scheduleType ?? .daily)
        _scheduleDays = State(initialValue: Set(habit.scheduleDays))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty
            && !(habit.type == .recurring && scheduleType == .daysOfWeek && scheduleDays.isEmpty)
    }

    var body: some View {
        NavigationStack {
            AppForm {
                Section("Привычка") {
                    TextField("Название", text: $name)
                }

                Section {
                    if habit.type == .conditional {
                        LabeledContent("Сложность", value: habit.difficulty.displayName)
                        LabeledContent("Длина челленджа", value: "\(habit.requiredDays ?? 0) дн.")
                    } else {
                        ColoredChipPicker(
                            items: HabitDifficulty.allCases,
                            selection: $difficulty,
                            icon: \.iconName,
                            label: \.displayName,
                            colors: \.chipColors
                        )
                    }
                } header: {
                    Text("Сложность")
                } footer: {
                    Text(habit.type == .conditional
                         ? "Сложность и длину челленджа нельзя менять после старта."
                         : "Новая сложность действует со следующего выполнения.")
                }

                if habit.type == .recurring {
                    Section("Расписание") {
                        Picker("Повтор", selection: $scheduleType) {
                            Text("Каждый день").tag(RecurringScheduleType.daily)
                            Text("Определённые дни").tag(RecurringScheduleType.daysOfWeek)
                        }
                        .pickerStyle(.segmented)

                        if scheduleType == .daysOfWeek {
                            DayOfWeekPicker(selection: $scheduleDays)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.25), value: scheduleType)
            .navigationTitle("Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Сохранить") { Task { await save() } }
                            .disabled(!isValid)
                    }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let request = UpdateHabitRequest(
            name: trimmedName,
            difficulty: habit.type == .conditional ? nil : difficulty,
            scheduleType: habit.type == .recurring ? scheduleType : nil,
            scheduleDays: habit.type == .recurring && scheduleType == .daysOfWeek
                ? scheduleDays.sorted() : nil
        )

        do {
            let updated: Habit = try await apiClient.patch("/habits/\(habit.id)", body: request)
            habitsViewModel.replace(updated)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
