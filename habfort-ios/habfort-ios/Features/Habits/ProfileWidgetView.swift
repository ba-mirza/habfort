import Auth
import SwiftUI

struct ProfileWidgetView: View {
    @Environment(AuthManager.self) private var authManager

    private var email: String {
        authManager.session?.user.email ?? "Account"
    }

    private var initial: String {
        email.first.map { String($0).uppercased() } ?? "?"
    }

    var body: some View {
        NavigationLink {
            SettingsView()
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Text(initial)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.accentColor)
                    }

                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()
            }
        }
    }
}
