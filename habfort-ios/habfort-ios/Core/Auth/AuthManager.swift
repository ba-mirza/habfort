import AuthenticationServices
import CryptoKit
import Foundation
import Supabase

@MainActor
@Observable
final class AuthManager {
    private(set) var session: Session?
    private(set) var isLoading = true

    private let client: SupabaseClient
    // Set right before presenting the Apple sign-in sheet, consumed when its
    // result comes back — Apple's nonce must be verified against the exact
    // value that was hashed into the original request.
    private var pendingAppleNonce: String?

    var accessToken: String? {
        session?.accessToken
    }

    // Lives for the app's lifetime (constructed once in habfort_iosApp) — no
    // need to hold/cancel this Task, it never outlives the process.
    init(client: SupabaseClient) {
        self.client = client
        Task { [weak self] in
            guard let self else { return }
            for await (_, session) in client.auth.authStateChanges {
                self.session = session
                self.isLoading = false
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    /// Returns `true` if sign-up produced an immediate session (email
    /// confirmation disabled), `false` if a confirmation email is pending.
    @discardableResult
    func signUp(email: String, password: String) async throws -> Bool {
        let response = try await client.auth.signUp(email: email, password: password)
        return response.session != nil
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Called from `SignInWithAppleButton`'s `onRequest` to attach a fresh
    /// nonce to the native Apple ID request.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        pendingAppleNonce = nonce
        request.requestedScopes = [.email, .fullName]
        request.nonce = Self.sha256(nonce)
    }

    /// Called from `SignInWithAppleButton`'s `onCompletion`.
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async throws {
        let authorization = try result.get()
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let identityTokenData = credential.identityToken,
            let identityToken = String(data: identityTokenData, encoding: .utf8),
            let nonce = pendingAppleNonce
        else {
            throw APIError(status: 0, message: "Не удалось получить данные Apple ID")
        }
        pendingAppleNonce = nil
        try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(provider: .apple, idToken: identityToken, nonce: nonce)
        )
    }

    func signInWithGoogle() async throws {
        try await client.auth.signInWithOAuth(provider: .google, redirectTo: AppConfig.oauthRedirectURL)
    }

    private static func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(status == errSecSuccess, "Unable to generate nonce")
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).compactMap { String(format: "%02x", $0) }.joined()
    }
}
