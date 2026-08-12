import AuthenticationServices
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
                    SecureField("Пароль", text: $password)
                        .textContentType(.password)
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
                            Text("Войти")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitting || email.isEmpty || password.isEmpty)
                .listRowBackground(Color.clear)

                Section {
                    HStack {
                        VStack { Divider() }
                        Text("или")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        VStack { Divider() }
                    }
                    .listRowSeparator(.hidden)

                    SignInWithAppleButton(.signIn) { request in
                        authManager.prepareAppleSignInRequest(request)
                    } onCompletion: { result in
                        Task {
                            do {
                                try await authManager.handleAppleSignInResult(result)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listRowBackground(Color.clear)

                    Button {
                        Task { await signInWithGoogle() }
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Продолжить с Google")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Вход")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button("Нет аккаунта? Регистрация") { showSignup = true }
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

    private func signInWithGoogle() async {
        errorMessage = nil
        do {
            try await authManager.signInWithGoogle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
