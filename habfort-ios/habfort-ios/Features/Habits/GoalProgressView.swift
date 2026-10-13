import SwiftUI

/// Progress from the wallet balance to the goal reward, on the colored header.
/// Past 80% the bar "speeds up" (warmer fill, a running shine) — the closer
/// the goal looks, the harder people push for it.
struct GoalProgressView: View {
    let balance: Int
    let goal: Reward?

    private var progress: Double {
        guard let goal, goal.costCoins > 0 else { return 0 }
        return min(1, max(0, Double(balance) / Double(goal.costCoins)))
    }

    private var isAccelerating: Bool { progress >= GoalMilestone.almostThereShare }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: progress >= 1 ? "gift.fill" : "target")
                Text(title)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(amountText)
                    .monospacedDigit()
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)

            if goal != nil {
                ProgressBar(progress: progress, isAccelerating: isAccelerating)
                    .frame(height: 10)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        guard let goal else { return "Добавь награду-цель в «Наградах»" }
        return progress >= 1 ? "Можно забрать: \(goal.name)" : goal.name
    }

    private var amountText: String {
        guard let goal else { return "\(balance)" }
        return "\(balance) / \(goal.costCoins)"
    }
}

private struct ProgressBar: View {
    let progress: Double
    let isAccelerating: Bool

    @State private var shineOffset: CGFloat = -1

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width * progress
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.25))

                Capsule()
                    .fill(isAccelerating
                          ? AnyShapeStyle(LinearGradient(colors: [.white, .yellow], startPoint: .leading, endPoint: .trailing))
                          : AnyShapeStyle(Color.white))
                    .frame(width: width)
                    .overlay {
                        if isAccelerating {
                            LinearGradient(colors: [.clear, .white.opacity(0.9), .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: max(24, width * 0.3))
                                .offset(x: shineOffset * width)
                                .clipShape(Capsule())
                        }
                    }
                    .clipShape(Capsule())
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        }
        .onAppear { startShine() }
        .onChange(of: isAccelerating) { startShine() }
    }

    private func startShine() {
        guard isAccelerating else { return }
        shineOffset = -1
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
            shineOffset = 1
        }
    }
}
