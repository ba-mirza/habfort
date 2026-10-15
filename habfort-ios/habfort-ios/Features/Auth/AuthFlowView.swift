import SwiftUI

/// Everything a signed-out user sees: a welcome screen, then the email form
/// for registering or signing in. Always light — the peach-to-white gradient
/// is built for it — whatever the app theme.
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
        .tint(AuthColors.ink)
        .environment(\.colorScheme, .light)
    }
}

/// Colors of the signed-out screens, taken from the brand artwork.
enum AuthColors {
    static let ink = Color(red: 0.11, green: 0.09, blue: 0.08)
    /// The asset color directly: `Color.accentColor` follows `.tint`, which
    /// these screens set to ink for the back button.
    static let accent = Color("AccentColor")
    static let brandOrange = Color(red: 0.78, green: 0.40, blue: 0.18)
    static let peach = Color(red: 0.98, green: 0.85, blue: 0.74)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.95)
}

/// Peach at the top, through the brand cream, into white.
struct AuthBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: AuthColors.peach, location: 0),
                .init(color: AuthColors.cream, location: 0.45),
                .init(color: .white, location: 0.8),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
            .shadow(color: AuthColors.brandOrange.opacity(0.35), radius: 18, y: 10)
            .accessibilityHidden(true)
    }
}

/// Large orange button (primary) or white outlined one (secondary).
struct AuthButtonStyle: ButtonStyle {
    var primary = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(primary ? Color.white : AuthColors.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                primary ? AuthColors.accent : Color.white,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                if !primary {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AuthColors.ink.opacity(0.1), lineWidth: 1)
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
                .padding(.bottom, 20)

            (Text("Beles ").foregroundStyle(AuthColors.ink) + Text("App").foregroundStyle(AuthColors.brandOrange))
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .padding(.bottom, 14)

            (Text("Добро пожаловать.\n").foregroundStyle(AuthColors.ink.opacity(0.45))
             + Text("Выполняй привычки, копи жетоны и трать их на награды").foregroundStyle(AuthColors.ink))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: -10) {
                ForEach(["bolt.fill", "flame.fill", "arrow.triangle.2.circlepath", "gift.fill"], id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AuthColors.accent)
                        .frame(width: 52, height: 52)
                        .background(.white, in: Circle())
                        .overlay(Circle().stroke(AuthColors.cream, lineWidth: 3))
                        .shadow(color: AuthColors.brandOrange.opacity(0.12), radius: 6, y: 3)
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
                        .foregroundStyle(AuthColors.ink)
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
