import Foundation

// MARK: - Player Stats Response (from GET /api/players/[id]/stats)
struct PlayerStatsResponse: Codable {
    let player: PlayerBasicInfo
    let lifetimeStats: LifetimeStats
    let attendanceStreak: Int
    let partnerChemistry: [PartnerStat]
    let nemesisOpponents: [NemesisStat]
    let badges: [EarnedBadge]
}

struct PlayerBasicInfo: Codable {
    let id: String
    let name: String
    let emoji: String
    let rating: Int
    let isActive: Bool
}

// MARK: - Lifetime Stats
struct LifetimeStats: Codable {
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let pointsFor: Int
    let pointsAgainst: Int
    let avgPointDiff: Double
    let sessionsAttended: Int
}

// MARK: - Partner Chemistry
struct PartnerStat: Codable, Identifiable {
    let partnerId: String
    let partnerName: String
    let partnerEmoji: String
    let gamesPlayed: Int
    let wins: Int
    let winRate: Double

    var id: String { partnerId }
}

// MARK: - Nemesis Opponents
struct NemesisStat: Codable, Identifiable {
    let opponentIds: [String]
    let opponentNames: [String]
    let opponentEmojis: [String]
    let gamesPlayed: Int
    let wins: Int
    let winRate: Double

    var id: String { opponentIds.joined(separator: "-") }
}
