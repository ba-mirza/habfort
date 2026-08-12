import Auth
import SwiftUI

struct ProfileWidgetView: View {
    @Environment(AuthManager.self) private var authManager
    let walletBalance: Int

    private var email: String {
        authManager.session?.user.email ?? "Аккаунт"
    }

    private var initial: String {
        email.first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
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

            HStack(spacing: 4) {
                Image(systemName: "seal.fill")
                Text("\(walletBalance)")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.25), in: Capsule())
        }
    }
}
