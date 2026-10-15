import Auth
import SwiftUI

/// Orange header of the Habits tab: greeting + profile link, and the goal
/// card — the balance is only ever shown against a goal, since distance to it
/// is what motivates. Past 80% the bar warms up and shines.
struct HabitsHeaderView: View {
    let balance: Int
    let goal: Reward?

    @Environment(AuthManager.self) private var authManager

    private var name: String {
        let email = authManager.session?.user.email ?? ""
        return email.split(separator: "@").first.map(String.init) ?? "друг"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NavigationLink {
                SettingsView()
            } label: {
                HStack(spacing: 12) {
                    Text(name.first.map { String($0).uppercased() } ?? "?")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 46, height: 46)
                        .brutalCard(fill: Color(.systemBackground), radius: 14, shadow: 2)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Привет,")
                            .font(.subheadline)
                        Text(name)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.black)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black.opacity(0.6))
                }
            }
            .buttonStyle(.plain)

            GoalCard(balance: balance, goal: goal)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background {
            UnevenRoundedRectangle(bottomLeadingRadius: 28, bottomTrailingRadius: 28, style: .continuous)
                .fill(Color.accentColor)
                .ignoresSafeArea(edges: .top)
        }
    }
}

private struct GoalCard: View {
    let balance: Int
    let goal: Reward?

    private var progress: Double {
        guard let goal, goal.costCoins > 0 else { return 0 }
        return min(1, Double(balance) / Double(goal.costCoins))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(goalTitle, systemImage: progress >= 1 ? "gift.fill" : "target")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(balance)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText(value: Double(balance)))
                    .animation(.snappy, value: balance)
                if let goal {
                    Text("/ \(goal.costCoins)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "seal.fill")
                    .font(.title3)
                    .foregroundStyle(Brutal.yellow)
                Spacer()
            }
            if goal != nil {
                GoalBar(progress: progress)
                    .frame(height: 14)
            }
        }
        .padding(16)
        .brutalCard()
        .accessibilityElement(children: .combine)
    }

    private var goalTitle: String {
        guard let goal else { return "Добавь награду-цель в «Наградах»" }
        return progress >= 1 ? "Можно забрать: \(goal.name)" : "Цель: \(goal.name)"
    }
}

private struct GoalBar: View {
    let progress: Double
    @State private var shine: CGFloat = -1

    private var isAccelerating: Bool { progress >= GoalMilestone.almostThereShare }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width * progress, progress > 0 ? 14 : 0)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.15))
                Capsule()
                    .fill(isAccelerating
                          ? AnyShapeStyle(LinearGradient(colors: [.accentColor, Brutal.yellow], startPoint: .leading, endPoint: .trailing))
                          : AnyShapeStyle(Color.accentColor))
                    .frame(width: width)
                    .overlay {
                        if isAccelerating {
                            LinearGradient(colors: [.clear, .white.opacity(0.8), .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: max(24, width * 0.3))
                                .offset(x: shine * width)
                        }
                    }
                    .clipShape(Capsule())
            }
            .overlay(Capsule().stroke(Brutal.ink, lineWidth: Brutal.stroke))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
        }
        .onAppear(perform: startShine)
        .onChange(of: isAccelerating) { startShine() }
    }

    private func startShine() {
        guard isAccelerating else { return }
        shine = -1
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) { shine = 1 }
    }
}
