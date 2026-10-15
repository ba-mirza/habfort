import Foundation

struct Me: Decodable {
    let id: String
    let email: String?
    let createdAt: String
    /// Short shareable id ("LYUvMnBVR3"). Optional for older API responses.
    let publicId: String?
    /// ISO 3166-1 alpha-2, nil until the user picks one.
    let country: String?
    /// Nil until first-run onboarding is finished (and the welcome bonus paid).
    let onboardedAt: String?
}
