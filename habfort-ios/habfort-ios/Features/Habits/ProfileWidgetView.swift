import Auth
import SwiftUI

struct ProfileWidgetView: View {
    @Environment(AuthManager.self) private var authManager
    let walletBalance: Int
    let goal: Reward?

    private var email: String {
        authManager.session?.user.email ?? "Аккаунт"
    }

    private var initial: String {
        email.first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                NavigationLink {
                    SettingsView()
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(initial)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }

                        Text(email)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // The balance is only ever shown against a goal — a bare number gives
            // no sense of distance, and distance is what motivates.
            GoalProgressView(balance: walletBalance, goal: goal)
                .padding(.top, 10)

        }
    }
}
