import AuthenticationServices
import SwiftUI

/// Sign in / sign up on one screen: email + password, or Sign in with Apple.
struct LoginView: View {
    enum Mode { case signIn, signUp }

    @Environment(AuthManager.self) private var authManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var confirmationSent = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    /// Supabase's own minimum.
    private let minPasswordLength = 6

    private var canSubmit: Bool {
        !isSubmitting && email.contains("@") && password.count >= (mode == .signUp ? minPasswordLength : 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            AccentHeader {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "seal.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Palette.yellow)
                    Text("Beles")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.onHeader)
                    Text("Привычки → жетоны → награды, которые выбираешь сам.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.onHeader.opacity(0.75))
                }
                .padding(.top, 24)
            }

            ScrollView {
                if confirmationSent {
                    ContentUnavailableView(
                        "Проверьте почту",
                        systemImage: "envelope",
                        description: Text("Мы отправили ссылку для подтверждения — войдите после подтверждения адреса.")
                    )
                    .padding(.top, 40)
                } else {
                    form
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(.systemBackground))
        .animation(.snappy, value: mode)
    }

    private var form: some View {
        VStack(spacing: 14) {
            Picker("Режим", selection: $mode) {
                Text("Вход").tag(Mode.signIn)
                Text("Регистрация").tag(Mode.signUp)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 6)

            field(icon: "envelope.fill") {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }

            field(icon: "lock.fill") {
                SecureField(mode == .signUp ? "Пароль (от \(minPasswordLength) символов)" : "Пароль", text: $password)
                    .textContentType(mode == .signUp ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { if canSubmit { Task { await submit() } } }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await submit() }
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text(mode == .signIn ? "Войти" : "Создать аккаунт")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!canSubmit)

            HStack {
                VStack { Divider() }
                Text("или")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                VStack { Divider() }
            }
            .padding(.vertical, 6)

            SignInWithAppleButton(mode == .signIn ? .signIn : .signUp) { request in
                authManager.prepareAppleSignInRequest(request)
            } onCompletion: { result in
                Task {
                    do {
                        try await authManager.handleAppleSignInResult(result)
                    } catch let error as ASAuthorizationError where error.code == .canceled {
                        // Closing the Apple sheet isn't an error worth showing.
                    } catch {
                        errorMessage = Self.message(for: error)
                    }
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            // The button's own label is fixed at creation; re-create it when
            // the mode flips so "Sign in" / "Sign up" follows.
            .id(mode)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 32)
    }

    private func field(icon: String, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            content()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .card(fill: Color.secondary.opacity(0.08), radius: 14, bordered: false)
    }

    private func submit() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            switch mode {
            case .signIn:
                try await authManager.signIn(email: email, password: password)
            case .signUp:
                let hasSession = try await authManager.signUp(email: email, password: password)
                confirmationSent = !hasSession
            }
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    /// Supabase answers in English; the common cases get a Russian message.
    private static func message(for error: Error) -> String {
        let text = error.localizedDescription.lowercased()
        if text.contains("invalid login credentials") { return "Неверный email или пароль." }
        if text.contains("already registered") || text.contains("already been registered") {
            return "Этот email уже зарегистрирован — попробуйте войти."
        }
        if text.contains("password should be") { return "Пароль слишком короткий или простой." }
        if text.contains("invalid") && text.contains("email") { return "Проверьте адрес email." }
        if (error as? URLError) != nil { return "Нет соединения с интернетом." }
        return error.localizedDescription
    }
}
