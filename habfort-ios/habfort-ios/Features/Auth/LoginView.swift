import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var showSignup = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                Button(isSubmitting ? "Logging in…" : "Log in") {
                    Task { await submit() }
                }
                .disabled(isSubmitting || email.isEmpty || password.isEmpty)
            }
            .navigationTitle("Log in")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("No account? Sign up") { showSignup = true }
                }
            }
            .sheet(isPresented: $showSignup) {
                SignupView()
            }
        }
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await authManager.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
