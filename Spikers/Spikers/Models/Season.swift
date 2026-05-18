import Foundation

// MARK: - Season
struct Season: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let number: Int
    let startedAt: String
    let scheduledStartAt: String?
    let announcedAt: String?
    let endedAt: String?
    let isActive: Bool
}

// MARK: - Season Detail
struct SeasonDetail: Codable {
    let id: String
    let name: String
    let number: Int
    let startedAt: String
    let scheduledStartAt: String?
    let announcedAt: String?
    let endedAt: String?
    let isActive: Bool
    let standings: [SeasonStanding]
    let sessions: [SeasonSession]
    let badges: [SeasonBadge]
}

struct SeasonStanding: Codable, Identifiable {
    let id: String
    let seasonId: String
    let playerId: String
    let finalRating: Int
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let pointsFor: Int
    let pointsAgainst: Int
    let longestWinStreak: Int
    let rank: Int
    let player: SeasonPlayer
}

struct SeasonPlayer: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
}

struct SeasonBadge: Codable, Identifiable {
    let id: String
    let playerId: String
    let badgeId: String
    let seasonId: String
    let earnedAt: String
    let player: SeasonPlayer
    let badge: Badge
}

struct SeasonSession: Codable, Identifiable {
    let id: String
    let date: String
    let location: String?
    let createdAt: String
    let status: SessionStatus
    let count: SeasonSessionCounts

    enum CodingKeys: String, CodingKey {
        case id, date, location, createdAt, status
        case count = "_count"
    }
}

struct SeasonSessionCounts: Codable {
    let games: Int
    let attendances: Int
}
