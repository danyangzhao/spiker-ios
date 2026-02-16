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
    let tournament: TournamentState?
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
    let clutchPlayer: AwardClutchPlayer?
    let theWall: AwardTheWall?
    let hotStreak: AwardHotStreak?
    let closestGame: GameHighlight?
    let biggestBlowout: GameHighlight?
    let highlights: [String]?
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

struct AwardClutchPlayer: Codable {
    let id: String
    let name: String
    let emoji: String
    let closeGameWins: Int
}

struct AwardTheWall: Codable {
    let id: String
    let name: String
    let emoji: String
    let avgPointsAgainst: Double
}

struct AwardHotStreak: Codable {
    let id: String
    let name: String
    let emoji: String
    let streak: Int
}

struct GameHighlight: Codable {
    let gameNumber: Int
    let scoreA: Int
    let scoreB: Int
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

// MARK: - Tournament
enum TournamentStatus: String, Codable {
    case ACTIVE
    case COMPLETED
    case ENDED
}

enum TournamentTeamMode: String, Codable {
    case RANDOM
    case FAIR
}

enum TournamentStage: String, Codable {
    case ROUND_ROBIN
    case BRACKET
    case FINALS
    case COMPLETED
    case ENDED
}

enum TournamentMatchStage: String, Codable {
    case ROUND_ROBIN
    case BRACKET
    case WINNERS_FINAL
    case LOSERS_FINAL
}

struct TournamentState: Codable, Identifiable {
    let id: String
    let sessionId: String
    let status: TournamentStatus
    let teamMode: TournamentTeamMode
    let stage: TournamentStage
    let createdAt: String
    let updatedAt: String
    let endedAt: String?
    let winnerTeamId: String?
    let teams: [TournamentTeam]
    let matches: [TournamentMatch]
}

struct TournamentTeam: Codable, Identifiable, Hashable {
    let id: String
    let tournamentId: String
    let name: String
    let seed: Int
    let wins: Int
    let losses: Int
    let isEliminated: Bool
    let playerAId: String
    let playerBId: String?
    let playerA: Player
    let playerB: Player?
}

struct TournamentMatch: Codable, Identifiable {
    let id: String
    let tournamentId: String
    let stage: TournamentMatchStage
    let round: Int
    let slot: Int
    let bestOf: Int
    let winsA: Int
    let winsB: Int
    let isComplete: Bool
    let teamAId: String?
    let teamBId: String?
    let winnerTeamId: String?
    let loserTeamId: String?
    let teamAPlayerIds: [String]
    let teamBPlayerIds: [String]
    let teamA: TournamentTeam?
    let teamB: TournamentTeam?
    let winnerTeam: TournamentTeam?
    let loserTeam: TournamentTeam?
    let games: [TournamentMatchGame]
}

struct TournamentMatchGame: Codable, Identifiable {
    let id: String
    let tournamentMatchId: String
    let gameId: String
    let gameNumber: Int
    let game: Game?
}
