import Foundation

// MARK: - RSVP Status
enum RSVPStatus: String, Codable {
    case GOING
    case MAYBE
    case OUT
}

// MARK: - RSVP Entry (from session detail)
struct RSVPEntry: Codable, Identifiable {
    let id: String
    let sessionId: String
    let playerId: String
    let status: RSVPStatus
    let updatedAt: String
    let player: Player
}

// MARK: - RSVP Response (from GET /api/sessions/[id]/rsvp)
struct RSVPResponse: Codable {
    let playerRsvps: [PlayerRSVP]
    let summary: RSVPSummary
}

struct PlayerRSVP: Codable, Identifiable {
    let player: Player
    let status: RSVPStatus?
    let updatedAt: String?

    var id: String { player.id }
}

struct RSVPSummary: Codable {
    let going: Int
    let maybe: Int
    let out: Int
    let noResponse: Int
}
