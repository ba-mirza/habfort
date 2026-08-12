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
                        "Проверьте почту",
                        systemImage: "envelope",
                        description: Text("Мы отправили ссылку для подтверждения — войдите после подтверждения адреса.")
                    )
                } else {
                    Form {
                        Section {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            SecureField("Пароль", text: $password)
                                .textContentType(.newPassword)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            Group {
                                if isSubmitting {
                                    ProgressView()
                                } else {
                                    Text("Зарегистрироваться")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(isSubmitting || email.isEmpty || password.count < 6)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Регистрация")
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
