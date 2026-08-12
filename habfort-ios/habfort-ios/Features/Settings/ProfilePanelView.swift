import SwiftUI

/// The profile hero: identity, one headline number, three supporting ones.
/// Always dark regardless of the app theme — the ring and the tiles are built
/// for a dark ground, and the panel reads as an instrument rather than as one
/// more list section.
struct ProfilePanelView: View {
    let email: String
    let viewModel: ProfileViewModel

    var body: some View {
        VStack(spacing: 18) {
            identity

            ProgressRing(
                value: viewModel.discipline?.rate,
                centerText: ringValue,
                caption: ringCaption
            )
            .frame(width: 190, height: 190)
            .padding(.top, 4)

            tiles
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.14, blue: 0.18), Color(red: 0.06, green: 0.07, blue: 0.09)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
    }

    private var identity: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(email.first.map { String($0).uppercased() } ?? "?")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(email)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if viewModel.isTodayClosed {
                    Text("сегодня всё закрыто")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "seal.fill")
                Text("\(viewModel.walletBalance)")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.15), in: Capsule())
        }
    }

    private var tiles: some View {
        HStack(alignment: .top, spacing: 12) {
            StatTileView(
                icon: "flame.fill",
                value: "\(viewModel.bestStreak)",
                label: "дней подряд"
            )
            StatTileView(
                icon: "checkmark.circle.fill",
                value: completedValue,
                label: "дней закрыто"
            )
            StatTileView(
                icon: "gift.fill",
                value: rewardValue,
                label: rewardLabel
            )
        }
    }

    private var ringValue: String {
        guard let rate = viewModel.discipline?.rate else { return "—" }
        return "\(Int((rate * 100).rounded()))%"
    }

    private var ringCaption: String {
        viewModel.discipline?.rate == nil
            ? "пока нечего считать"
            : "дисциплина\nза 30 дней"
    }

    private var completedValue: String {
        guard let discipline = viewModel.discipline, discipline.totalPlanned > 0 else { return "—" }
        return "\(discipline.totalCompleted)/\(discipline.totalPlanned)"
    }

    private var rewardValue: String {
        guard let progress = viewModel.rewardProgress else { return "—" }
        return "\(Int((progress * 100).rounded()))%"
    }

    private var rewardLabel: String {
        viewModel.nextReward.map { "до «\($0.name)»" } ?? "нет наград"
    }
}

struct StatTileView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}
