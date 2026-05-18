import Foundation

// MARK: - Season
struct Season: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let number: Int
    let startedAt: String
    let scheduledStartAt: String?
    let announcedAt: String?
    let carryOverPlayerIds: [String]
    let endedAt: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, number, startedAt, scheduledStartAt, announcedAt, carryOverPlayerIds, endedAt, isActive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        number = try container.decode(Int.self, forKey: .number)
        startedAt = try container.decode(String.self, forKey: .startedAt)
        scheduledStartAt = try container.decodeIfPresent(String.self, forKey: .scheduledStartAt)
        announcedAt = try container.decodeIfPresent(String.self, forKey: .announcedAt)
        carryOverPlayerIds = try container.decodeIfPresent([String].self, forKey: .carryOverPlayerIds) ?? []
        endedAt = try container.decodeIfPresent(String.self, forKey: .endedAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
    }
}

// MARK: - Season Detail
struct SeasonDetail: Codable {
    let id: String
    let name: String
    let number: Int
    let startedAt: String
    let scheduledStartAt: String?
    let announcedAt: String?
    let carryOverPlayerIds: [String]
    let endedAt: String?
    let isActive: Bool
    let standings: [SeasonStanding]
    let sessions: [SeasonSession]
    let badges: [SeasonBadge]

    enum CodingKeys: String, CodingKey {
        case id, name, number, startedAt, scheduledStartAt, announcedAt, carryOverPlayerIds, endedAt, isActive, standings, sessions, badges
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        number = try container.decode(Int.self, forKey: .number)
        startedAt = try container.decode(String.self, forKey: .startedAt)
        scheduledStartAt = try container.decodeIfPresent(String.self, forKey: .scheduledStartAt)
        announcedAt = try container.decodeIfPresent(String.self, forKey: .announcedAt)
        carryOverPlayerIds = try container.decodeIfPresent([String].self, forKey: .carryOverPlayerIds) ?? []
        endedAt = try container.decodeIfPresent(String.self, forKey: .endedAt)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        standings = try container.decode([SeasonStanding].self, forKey: .standings)
        sessions = try container.decode([SeasonSession].self, forKey: .sessions)
        badges = try container.decode([SeasonBadge].self, forKey: .badges)
    }
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
