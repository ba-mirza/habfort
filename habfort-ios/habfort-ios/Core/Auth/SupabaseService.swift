import Foundation
import Supabase

// Auth only — the app never talks to Supabase Postgres directly; all data
// goes through the NestJS API with this client's session token.
enum SupabaseService {
    static let shared = SupabaseClient(
        supabaseURL: AppConfig.supabaseURL,
        supabaseKey: AppConfig.supabaseAnonKey
    )
}
