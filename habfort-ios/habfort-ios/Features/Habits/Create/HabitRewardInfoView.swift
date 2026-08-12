import SwiftUI

/// Explains what the chosen difficulty and type actually pay out. The numbers
/// come from GET /economy, so they can't drift from what the backend awards.
struct HabitRewardInfoView: View {
    let viewModel: CreateHabitViewModel

    var body: some View {
        if let economy = viewModel.economy {
            VStack(alignment: .leading, spacing: 10) {
                if let coins = viewModel.coinsForSelectedDifficulty {
                    HStack {
                        Text("За выполнение")
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "seal.fill")
                            Text("\(coins)")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                }

                Text(presetsLine(economy))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(typeExplanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Если за день выполнить всё запланированное, сверху начислится бонус: \(economy.fullDayBonus.weekday) в будни, \(economy.fullDayBonus.weekend) в выходные.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func presetsLine(_ economy: EconomyConfig) -> String {
        let parts = HabitDifficulty.allCases.compactMap { difficulty -> String? in
            guard let coins = economy.coins(for: difficulty) else { return nil }
            return "\(difficulty.displayName) — \(coins)"
        }
        return parts.joined(separator: " · ")
    }

    private var typeExplanation: String {
        switch viewModel.type {
        case .instant:
            "Разовая: жетоны начислятся один раз, после выполнения привычка уйдёт в историю."
        case .conditional:
            conditionalExplanation
        case .recurring:
            "Регулярная: жетоны начисляются каждый раз при выполнении по расписанию, привычка остаётся в списке."
        }
    }

    private var conditionalExplanation: String {
        let base = "Челлендж: полные жетоны — только если пройти все дни подряд. Если прервёшь, начислится пропорционально пройденным дням."
        guard let perDay = viewModel.partialCoinsPerDay, let days = Int(viewModel.requiredDaysText), days >= 1 else {
            return base
        }
        return base + " Например, 1 день из \(days) — примерно \(perDay)."
    }
}
