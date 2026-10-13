import SwiftUI

/// Drops in from the top when a completion pushes the balance past 80% of the
/// goal, or onto the goal itself.
struct GoalMilestoneBanner: View {
    let milestone: GoalMilestone

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: milestone.kind == .reached ? "gift.fill" : "flame.fill")
                .font(.title2)
                .foregroundStyle(milestone.kind == .reached ? Color.green : Color.orange)
                .symbolEffect(.bounce, value: milestone.id)
            VStack(alignment: .leading, spacing: 2) {
                Text(milestone.kind == .reached ? "Цель достигнута!" : "Почти у цели!")
                    .font(.headline)
                Text(milestone.kind == .reached
                     ? "Жетонов хватает на «\(milestone.goalName)» — забирай в «Наградах»."
                     : "До «\(milestone.goalName)» осталось всего \(milestone.coinsLeft) жетонов.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .sensoryFeedback(.success, trigger: milestone.id)
        .accessibilityElement(children: .combine)
    }
}
