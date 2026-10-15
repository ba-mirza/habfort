import SwiftUI

/// Everything a signed-out user sees: a welcome screen, then the email form
/// for registering or signing in. Always dark — the warm gradient is built
/// for it — whatever the app theme.
struct AuthFlowView: View {
    @State private var path: [AuthFormView.Mode] = Self.initialPath

    /// Debug builds can open straight on the form with `-initialTab signup`.
    private static var initialPath: [AuthFormView.Mode] {
        #if DEBUG
        UserDefaults.standard.string(forKey: "initialTab") == "signup" ? [.signUp] : []
        #else
        []
        #endif
    }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(
                onRegister: { path.append(.signUp) },
                onSignIn: { path.append(.signIn) }
            )
            .navigationDestination(for: AuthFormView.Mode.self) { mode in
                AuthFormView(initialMode: mode)
            }
        }
        .tint(.white)
        .environment(\.colorScheme, .dark)
    }
}

/// Orange glow at the top fading into near-black.
struct AuthBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.06)
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.96, green: 0.62, blue: 0.20), location: 0),
                    .init(color: Color(red: 0.62, green: 0.27, blue: 0.08), location: 0.25),
                    .init(color: Color(red: 0.20, green: 0.09, blue: 0.05), location: 0.5),
                    .init(color: .clear, location: 0.75),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

struct AppLogo: View {
    var size: CGFloat = 96

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
            .accessibilityHidden(true)
    }
}

/// Large light button (primary) or dark translucent one (secondary).
struct AuthButtonStyle: ButtonStyle {
    var primary = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(primary ? Color.black : Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                primary ? Color.white.opacity(0.92) : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                if !primary {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct WelcomeView: View {
    let onRegister: () -> Void
    let onSignIn: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AppLogo()
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 28)

            (Text("Добро пожаловать в Beles.\n").foregroundStyle(.white.opacity(0.5))
             + Text("Выполняй привычки, копи жетоны и трать их на награды").foregroundStyle(.white))
                .font(.system(.title, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: -10) {
                ForEach(["bolt.fill", "flame.fill", "arrow.triangle.2.circlepath", "gift.fill"], id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(width: 52, height: 52)
                        .background(Color(white: 0.16), in: Circle())
                        .overlay(Circle().stroke(Color(red: 0.05, green: 0.05, blue: 0.06), lineWidth: 3))
                }
            }
            .padding(.top, 24)
            .accessibilityHidden(true)

            Spacer()
            Spacer()

            VStack(spacing: 12) {
                Button(action: onRegister) {
                    Text("Создать аккаунт")
                }
                .buttonStyle(AuthButtonStyle())
                .overlay(alignment: .topTrailing) {
                    Text("Бесплатно")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.45, green: 0.85, blue: 0.62), in: Capsule())
                        .rotationEffect(.degrees(4))
                        .offset(x: -8, y: -10)
                        .accessibilityHidden(true)
                }

                Button(action: onSignIn) {
                    Text("Уже есть аккаунт?")
                }
                .buttonStyle(AuthButtonStyle(primary: false))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(AuthBackground())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { appeared = true }
        }
    }
}
