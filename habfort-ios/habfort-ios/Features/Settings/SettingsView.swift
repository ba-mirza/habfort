import Auth
import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        List {
            Section {
                if let email = authManager.session?.user.email {
                    LabeledContent("Email", value: email)
                }
            }

            Section {
                Button("Log Out", role: .destructive) {
                    Task { try? await authManager.signOut() }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
