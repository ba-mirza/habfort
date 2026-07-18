import Foundation
import Supabase

@MainActor
@Observable
final class AuthManager {
    private(set) var session: Session?
    private(set) var isLoading = true

    private let client: SupabaseClient

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
}
