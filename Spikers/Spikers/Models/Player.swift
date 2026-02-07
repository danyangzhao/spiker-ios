import Foundation

// MARK: - Player (matches Prisma Player model)
struct Player: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let createdAt: String
    let isActive: Bool
    let rating: Int

    // Optional: included when fetching a single player with badges
    let playerBadges: [PlayerBadgeEntry]?
}

// MARK: - PlayerBadge join (from GET /api/players/[id])
struct PlayerBadgeEntry: Codable, Identifiable, Hashable {
    let id: String
    let playerId: String
    let badgeId: String
    let earnedAt: String
    let badge: Badge
}
