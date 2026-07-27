import SwiftUI

struct FilterWidgetView: View {
    @Binding var typeFilter: HabitType?
    @Binding var difficultyFilter: HabitDifficulty?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Type", selection: $typeFilter) {
                Text("All types").tag(HabitType?.none)
                ForEach(HabitType.allCases) { type in
                    Text(type.displayName).tag(Optional(type))
                }
            }
            .pickerStyle(.segmented)

            Picker("Difficulty", selection: $difficultyFilter) {
                Text("All difficulties").tag(HabitDifficulty?.none)
                ForEach(HabitDifficulty.allCases) { difficulty in
                    Text(difficulty.displayName).tag(Optional(difficulty))
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }
}
