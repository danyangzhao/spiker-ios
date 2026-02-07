import Foundation

// MARK: - Badge Service
/// Handles all /api/badges endpoints
struct BadgeService {
    private let client = APIClient.shared

    /// GET /api/badges - List all available badges
    func fetchBadges() async throws -> [Badge] {
        try await client.get("/api/badges")
    }
}
