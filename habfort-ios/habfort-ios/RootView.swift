import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .task {
                        try? await Task.sleep(for: .seconds(1.6))
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                        }
                    }
            } else if authManager.isLoading {
                ProgressView()
            } else if authManager.session != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
