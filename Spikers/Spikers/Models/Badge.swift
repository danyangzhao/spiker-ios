import Foundation

// MARK: - Badge (from GET /api/badges)
struct Badge: Codable, Identifiable, Hashable {
    let id: String
    let code: String
    let name: String
    let description: String
    let iconEmoji: String
}

// MARK: - Earned Badge (from player stats response)
struct EarnedBadge: Codable, Identifiable {
    let id: String
    let code: String
    let name: String
    let description: String
    let iconEmoji: String
    let earnedAt: String
}

// MARK: - Badge Progress (for locked badges)
struct BadgeProgress: Codable {
    let code: String
    let current: Int
    let target: Int
}
