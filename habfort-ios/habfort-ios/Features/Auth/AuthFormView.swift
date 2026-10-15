import AuthenticationServices
import SwiftUI

/// Email + password form for registering or signing in, with Sign in with
/// Apple below. Field problems show under the field; everything else drops
/// in as a toast at the top.
struct AuthFormView: View {
    enum Mode: Hashable { case signUp, signIn }

    @Environment(AuthManager.self) private var authManager
    @State private var mode: Mode
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var toast: String?
    @State private var isSubmitting = false
    @State private var confirmationSent = false
    @State private var legalDocument: LegalDocument?
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    /// Supabase's own minimum.
    private let minPasswordLength = 6

    init(initialMode: Mode) {
        _mode = State(initialValue: initialMode)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                AppLogo(size: 64)
                    .padding(.top, 12)

                Text(mode == .signUp ? "Регистрация в Beles" : "С возвращением")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(AuthColors.ink)
                    .padding(.bottom, 14)
                    .contentTransition(.opacity)

                if confirmationSent {
                    Label("Мы отправили письмо для подтверждения. Подтвердите адрес и войдите.", systemImage: "envelope.fill")
                        .foregroundStyle(AuthColors.ink.opacity(0.8))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                AuthField(error: emailError) {
                    TextField("", text: $email, prompt: Text("Email").foregroundStyle(AuthColors.ink.opacity(0.35)))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }

                AuthField(error: passwordError) {
                    HStack {
                        Group {
                            if showPassword {
                                TextField("", text: $password, prompt: passwordPrompt)
                            } else {
                                SecureField("", text: $password, prompt: passwordPrompt)
                            }
                        }
                        .textContentType(mode == .signUp ? .newPassword : .password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await submit() } }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(AuthColors.ink.opacity(0.4))
                        }
                        .accessibilityLabel(showPassword ? "Скрыть пароль" : "Показать пароль")
                    }
                }

                Button {
                    Task { await submit() }
                } label: {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text("Продолжить с email")
                    }
                }
                .buttonStyle(AuthButtonStyle())
                .disabled(isSubmitting)

                HStack(spacing: 12) {
                    Rectangle().fill(AuthColors.ink.opacity(0.1)).frame(height: 1)
                    Text("или").font(.subheadline).foregroundStyle(AuthColors.ink.opacity(0.4))
                    Rectangle().fill(AuthColors.ink.opacity(0.1)).frame(height: 1)
                }
                .padding(.vertical, 6)

                SignInWithAppleButton(mode == .signUp ? .signUp : .signIn) { request in
                    authManager.prepareAppleSignInRequest(request)
                } onCompletion: { result in
                    Task { await handleApple(result) }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                // The button's label is fixed when it's created; rebuild it
                // when the mode flips so it follows.
                .id(mode)

                legalText
                    .padding(.top, 10)

                Button {
                    withAnimation(.snappy) {
                        mode = mode == .signUp ? .signIn : .signUp
                        emailError = nil
                        passwordError = nil
                        confirmationSent = false
                    }
                } label: {
                    Text(mode == .signUp ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AuthColors.ink.opacity(0.55))
                }
                .padding(.top, 18)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AuthBackground())
        .overlay(alignment: .top) {
            if let toast {
                AuthToast(message: toast) { self.toast = nil }
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast) {
                        try? await Task.sleep(for: .seconds(4))
                        self.toast = nil
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: toast)
        .animation(.snappy, value: emailError)
        .animation(.snappy, value: passwordError)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $legalDocument) { document in
            LegalDocumentView(document: document)
        }
    }

    private var passwordPrompt: Text {
        Text(mode == .signUp ? "Пароль (от \(minPasswordLength) символов)" : "Пароль")
            .foregroundStyle(AuthColors.ink.opacity(0.35))
    }

    private var legalText: some View {
        VStack(spacing: 2) {
            Text(mode == .signUp ? "Регистрируясь, вы соглашаетесь с" : "Продолжая, вы соглашаетесь с")
                .foregroundStyle(AuthColors.ink.opacity(0.5))
            HStack(spacing: 4) {
                Button("Политикой конфиденциальности") { legalDocument = .privacy }
                Text("и").foregroundStyle(AuthColors.ink.opacity(0.5))
                Button("Условиями") { legalDocument = .terms }
            }
            .foregroundStyle(AuthColors.brandOrange)
            .fontWeight(.semibold)
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func submit() async {
        emailError = nil
        passwordError = nil
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if !email.contains("@") || !email.contains(".") {
            emailError = "Проверьте адрес email"
        }
        if mode == .signUp && password.count < minPasswordLength {
            passwordError = "Минимум \(minPasswordLength) символов"
        } else if password.isEmpty {
            passwordError = "Введите пароль"
        }
        guard emailError == nil, passwordError == nil else { return }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            switch mode {
            case .signIn:
                try await authManager.signIn(email: email, password: password)
            case .signUp:
                let hasSession = try await authManager.signUp(email: email, password: password)
                confirmationSent = !hasSession
            }
        } catch {
            show(error)
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        do {
            try await authManager.handleAppleSignInResult(result)
        } catch {
            guard !UserFacingError.isCancellation(error) else { return }
            show(error)
        }
    }

    /// Field-specific problems go under their field (with a toast too, since
    /// the field may be scrolled away); everything else only toasts.
    private func show(_ error: Error) {
        let message = UserFacingError.message(for: error)
        if message.hasPrefix("Этот email уже") {
            emailError = "Этот email уже зарегистрирован"
            toast = "Аккаунт уже существует.\nВойдите или укажите другой email."
        } else if message.hasPrefix("Неверный email") {
            passwordError = "Неверный email или пароль"
            toast = message
        } else if message.hasPrefix("Пароль слишком") {
            passwordError = "Слишком простой пароль"
            toast = message
        } else if message.hasPrefix("Проверьте адрес") {
            emailError = "Проверьте адрес email"
        } else {
            toast = message
        }
    }
}

/// White input with an optional red error tag attached underneath.
private struct AuthField<Content: View>: View {
    let error: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
                .foregroundStyle(error == nil ? AuthColors.ink : Color(red: 0.8, green: 0.2, blue: 0.2))
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(error == nil ? AuthColors.ink.opacity(0.1) : Color.red.opacity(0.6), lineWidth: 1)
                )

            if let error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.82, green: 0.22, blue: 0.24), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

/// White capsule at the top with an icon, the message and a close button.
private struct AuthToast: View {
    let message: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.circle")
                .font(.title2)
                .foregroundStyle(Color(red: 0.85, green: 0.25, blue: 0.25))
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AuthColors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AuthColors.ink.opacity(0.45))
            }
            .accessibilityLabel("Закрыть")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
        .sensoryFeedback(.error, trigger: message)
    }
}
