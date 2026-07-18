import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            AccountStatusView()
                .tabItem { Label("Habits", systemImage: "checklist") }

            Text("Rewards — Phase 5")
                .tabItem { Label("Rewards", systemImage: "gift") }

            Text("History — Phase 6")
                .tabItem { Label("History", systemImage: "clock") }
        }
    }
}

// Temporary Phase 1 placeholder proving the auth + API round trip end to
// end — Phase 2 replaces this tab's content with the real Profile/Filter/List widgets.
private struct AccountStatusView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(APIClient.self) private var apiClient
    @State private var me: Me?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if let me {
                    Text("Signed in as \(me.email ?? me.id)")
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else {
                    ProgressView()
                }
                Button("Log out", role: .destructive) {
                    Task { try? await authManager.signOut() }
                }
            }
            .navigationTitle("Habits")
            .task {
                await loadMe()
            }
        }
    }

    private func loadMe() async {
        do {
            me = try await apiClient.get("/me")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
