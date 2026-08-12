import Foundation

// Supabase anon key is designed to be safe to embed in a client app (it's the
// public key, not the service_role secret) — same as VITE_SUPABASE_ANON_KEY
// was in the web frontend. API base URL isn't sensitive either.
nonisolated enum AppConfig {
    #if DEBUG
    static let apiBaseURL = URL(string: "http://localhost:3001")!
    #else
    // TODO: point at the deployed backend once it exists.
    static let apiBaseURL = URL(string: "http://localhost:3001")!
    #endif

    static let supabaseURL = URL(string: "https://roltsakilealicnrywtm.supabase.co")!

    // Custom URL scheme Supabase redirects back into after a web-based OAuth
    // flow (Google). Must be registered as a URL Type in the Xcode target's
    // Info settings AND added to Supabase Dashboard → Auth → URL Configuration
    // → Redirect URLs — neither is doable from code, see setup checklist.
    static let oauthRedirectURL = URL(string: "habfort-ios://login-callback")!
    static let supabaseAnonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJvbHRzYWtpbGVhbGljbnJ5d3RtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyMjQ1OTQsImV4cCI6MjA5OTgwMDU5NH0.3L6WlhRYSjLHxPIYRhx4RPnvn5CdEi4MripjMw2IWNA"
}
