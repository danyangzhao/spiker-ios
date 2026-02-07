import Foundation

// MARK: - Session Status
enum SessionStatus: String, Codable {
    case UPCOMING
    case IN_PROGRESS
    case COMPLETED
}

// MARK: - Session (from GET /api/sessions list)
struct Session: Codable, Identifiable {
    let id: String
    let date: String
    let location: String?
    let createdAt: String
    let status: SessionStatus

    // Included in list responses
    let _count: SessionCounts?
}

struct SessionCounts: Codable {
    let games: Int
    let attendances: Int
}

// MARK: - Session Detail (from GET /api/sessions/[id])
struct SessionDetail: Codable, Identifiable {
    let id: String
    let date: String
    let location: String?
    let createdAt: String
    let status: SessionStatus
    let attendances: [Attendance]
    let rsvps: [RSVPEntry]
    let games: [Game]
}

// MARK: - Attendance
struct Attendance: Codable, Identifiable {
    let id: String
    let sessionId: String
    let playerId: String
    let present: Bool
    let player: Player
}

// MARK: - Session Summary (from GET /api/sessions/[id]/summary)
struct SessionSummary: Codable {
    let session: SessionInfo
    let playersPresent: [PlayerInfo]
    let totalGames: Int?
    let playerOfTheDay: AwardPlayerOfDay?
    let ironman: AwardIronman?
    let socialButterfly: AwardSocialButterfly?
    let playerStats: [SessionPlayerStat]?
}

struct SessionInfo: Codable {
    let id: String
    let date: String
    let location: String?
    let status: SessionStatus
}

struct PlayerInfo: Codable, Identifiable {
    let id: String
    let name: String
    let emoji: String
}

struct AwardPlayerOfDay: Codable {
    let id: String
    let name: String
    let emoji: String
    let wins: Int
}

struct AwardIronman: Codable {
    let id: String
    let name: String
    let emoji: String
    let gamesPlayed: Int
}

struct AwardSocialButterfly: Codable {
    let id: String
    let name: String
    let emoji: String
    let uniqueTeammates: Int
}

struct SessionPlayerStat: Codable, Identifiable {
    let id: String
    let name: String
    let emoji: String
    let gamesPlayed: Int
    let wins: Int
    let losses: Int
    let pointDiff: Int
}
