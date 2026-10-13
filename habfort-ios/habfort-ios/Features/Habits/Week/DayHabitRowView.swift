import SwiftUI

/// Read-only row for a day other than today.
struct DayHabitRowView: View {
    let entry: DayHabitEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .font(.system(size: 22))
                .foregroundStyle(statusColor)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body)
                    .foregroundStyle(entry.status == .planned ? .primary : .secondary)
                Label(statusText, systemImage: entry.type.iconName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var statusIcon: String {
        switch entry.status {
        case .done: "checkmark.circle.fill"
        case .missed: "xmark.circle"
        case .planned: "circle.dotted"
        }
    }

    private var statusColor: Color {
        switch entry.status {
        case .done: .green
        case .missed: .red
        case .planned: .secondary
        }
    }

    private var statusText: String {
        switch entry.status {
        case .done: "Выполнено"
        case .missed: "Пропущено"
        case .planned: "Запланировано"
        }
    }
}
