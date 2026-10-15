import SwiftUI

/// First-run flow: a welcome bonus, a small first goal, and how coins get
/// there. Shown once; finishing it credits the bonus on the backend.
struct OnboardingView: View {
    let onFinish: () -> Void

    @Environment(APIClient.self) private var apiClient
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            stepIndicator
                .padding(.top, 16)

            Group {
                switch viewModel.step {
                case .welcome: welcomeStep
                case .goal: goalStep
                case .howItWorks: howItWorksStep
                }
            }
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }

            primaryButton
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .animation(.snappy, value: viewModel.step)
        .task { await viewModel.loadEconomy(apiClient: apiClient) }
        .interactiveDismissDisabled()
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            CoinBurstView()
                .frame(width: 160, height: 160)
            Text("Добро пожаловать!")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            Text("Держи \(viewModel.welcomeBonus) жетонов на старт.\nВыполняй привычки, копи жетоны и трать их на награды, которые выбираешь сам.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var goalStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Выбери первую цель")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("Маленькая цель, до которой пара дней, работает лучше большой мечты.")
                    .foregroundStyle(.secondary)

                ForEach(RewardTemplate.all) { template in
                    templateRow(template)
                }

                customGoalCard

                if viewModel.isGoalTooBig {
                    Label("Первая цель лучше маленькая — до этой придётся долго копить. Можно оставить, но большую мечту проще добавить второй.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var howItWorksStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text("Как это работает")
                .font(.system(.title, design: .rounded, weight: .bold))
            flowRow(icon: "checkmark.circle.fill", color: .green, title: "Выполняй привычки", subtitle: "Лёгкая, средняя или сложная — за каждую фиксированные жетоны.")
            flowRow(icon: "seal.fill", color: .accentColor, title: "Копи жетоны", subtitle: "Уже есть \(viewModel.welcomeBonus) — до «\(viewModel.goalName)» осталось \(viewModel.coinsLeftAfterBonus).")
            flowRow(icon: "gift.fill", color: .orange, title: "Забирай награду", subtitle: viewModel.daysToGoal > 0
                    ? "Примерно \(viewModel.daysToGoal) \(dayWord(viewModel.daysToGoal)) с одной привычкой средней сложности."
                    : "Жетонов уже хватает!")
            Spacer()
        }
        .padding(24)
    }

    // MARK: - Pieces

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.step.rawValue ? Color.accentColor : Color.secondary.opacity(0.25))
                    .frame(width: step == viewModel.step ? 24 : 8, height: 8)
            }
        }
    }

    private var primaryButton: some View {
        Button {
            Task { await advance() }
        } label: {
            Group {
                if viewModel.isSubmitting {
                    ProgressView()
                } else {
                    Text(primaryTitle)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isSubmitting || (viewModel.step == .goal && !viewModel.isGoalValid))
    }

    private var primaryTitle: String {
        switch viewModel.step {
        case .welcome: "Забрать жетоны"
        case .goal: "Дальше"
        case .howItWorks: "Начать"
        }
    }

    private func advance() async {
        switch viewModel.step {
        case .welcome: viewModel.step = .goal
        case .goal: viewModel.step = .howItWorks
        case .howItWorks:
            if await viewModel.finish(apiClient: apiClient) {
                onFinish()
            }
        }
    }

    private func templateRow(_ template: RewardTemplate) -> some View {
        let isSelected = !viewModel.isCustom && viewModel.selectedTemplate == template
        return Button {
            viewModel.isCustom = false
            viewModel.selectedTemplate = template
        } label: {
            HStack(spacing: 12) {
                Image(systemName: template.icon)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(Color.accentColor)
                    .background(Color.accentColor.opacity(0.12), in: Circle())
                Text(template.name)
                    .foregroundStyle(.primary)
                Spacer()
                Label("\(template.costCoins)", systemImage: "seal.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.accentColor)
            }
            .padding(12)
            .card()
            .overlay {
                RoundedRectangle(cornerRadius: Palette.radius, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private var customGoalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                viewModel.isCustom = true
            } label: {
                Label("Своя награда", systemImage: "pencil")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            if viewModel.isCustom {
                TextField("Название", text: $viewModel.customName)
                    .textFieldStyle(.roundedBorder)
                TextField("Цена в жетонах (от \(viewModel.minCost))", text: $viewModel.customCostText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(12)
        .card()
        .overlay {
            RoundedRectangle(cornerRadius: Palette.radius, style: .continuous)
                .stroke(viewModel.isCustom ? Color.accentColor : .clear, lineWidth: 2)
        }
    }

    private func flowRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).foregroundStyle(.secondary)
            }
        }
    }

    private func dayWord(_ n: Int) -> String {
        russianPlural(n, one: "день", few: "дня", many: "дней")
    }
}

/// A coin that pops in and pulses, with sparkles around it.
private struct CoinBurstView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                    .offset(y: appeared ? -72 : -20)
                    .rotationEffect(.degrees(Double(index) * 45))
                    .opacity(appeared ? 1 : 0)
            }
            Image(systemName: "seal.fill")
                .font(.system(size: 96))
                .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                .scaleEffect(appeared ? 1 : 0.3)
                .symbolEffect(.pulse, options: .repeating, isActive: appeared)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .accessibilityHidden(true)
    }
}
