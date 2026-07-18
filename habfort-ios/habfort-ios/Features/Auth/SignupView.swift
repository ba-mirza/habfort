import SwiftUI

struct SignupView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var confirmationSent = false

    var body: some View {
        NavigationStack {
            Group {
                if confirmationSent {
                    ContentUnavailableView(
                        "Check your email",
                        systemImage: "envelope",
                        description: Text("We sent a confirmation link — log in once you've confirmed your address.")
                    )
                } else {
                    Form {
                        Section {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            SecureField("Password", text: $password)
                                .textContentType(.newPassword)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }

                        Button(isSubmitting ? "Signing up…" : "Sign up") {
                            Task { await submit() }
                        }
                        .disabled(isSubmitting || email.isEmpty || password.count < 6)
                    }
                }
            }
            .navigationTitle("Sign up")
        }
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let hasSession = try await authManager.signUp(email: email, password: password)
            if hasSession {
                dismiss()
            } else {
                confirmationSent = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
