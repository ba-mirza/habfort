import SwiftUI

/// Placeholder for the upcoming invites/lobby feature — the layout only;
/// numbers and the code are illustrative and nothing is wired to a backend.
struct InviteFriendsView: View {
    private let invited = 3
    private let tierGoal = 10
    private let code = "BELES-37021"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                hero
                tierCard
                HStack(spacing: 12) {
                    statTile(title: "Жетонов получено", value: "45", icon: "seal.fill", color: .accentColor)
                    statTile(title: "Ждут награды", value: "3", icon: "clock.fill", color: Color(red: 0.85, green: 0.42, blue: 0.85))
                }
                codeSection
                ComingSoonNote()
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Друзья")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 30, weight: .semibold))
            Text("Пригласи друзей")
                .font(.system(.title, design: .rounded, weight: .bold))
            Text("Выполняйте привычки вместе в общем лобби и получайте жетоны, когда друг закрывает свою первую неделю.")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.75))
        }
        .foregroundStyle(.black)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(fill: Palette.purple.opacity(0.85), radius: 22, bordered: false)
    }

    private var tierCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Командный игрок")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                Spacer()
                Text("\(invited) / \(tierGoal)")
                    .font(.system(.title2, design: .rounded, weight: .heavy))
            }
            HStack(spacing: 4) {
                ForEach(0..<tierGoal, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index < invited ? Color.white : Color.white.opacity(0.18))
                        .frame(height: 10)
                }
            }
            Text("Пригласи ещё \(tierGoal - invited), чтобы открыть уровень «Лидер стаи».")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .foregroundStyle(.white)
        .padding(18)
        .card(fill: Color(red: 0.1, green: 0.1, blue: 0.11), radius: 22, bordered: false)
    }

    private func statTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer()
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(value)
                .font(.system(.title, design: .rounded, weight: .heavy))
        }
        .foregroundStyle(.black)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(fill: color, radius: 18, bordered: false)
    }

    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Твой код приглашения")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .padding(.top, 6)
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .frame(width: 34, height: 34)
                    .card(fill: Color.secondary.opacity(0.12), radius: 10, bordered: false)
                Text(code)
                    .font(.system(.body, design: .monospaced, weight: .semibold))
                Spacer()
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .card()

            Button {} label: {
                Label("Поделиться", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(true)
        }
    }
}

/// Shared footer for placeholder screens.
struct ComingSoonNote: View {
    var body: some View {
        Label("Скоро — это превью будущей функции", systemImage: "hammer.fill")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}
