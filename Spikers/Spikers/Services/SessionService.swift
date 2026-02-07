import Foundation

// MARK: - Session Service
/// Handles all /api/sessions endpoints
struct SessionService {
    private let client = APIClient.shared

    /// GET /api/sessions - List sessions
    func fetchSessions(status: SessionStatus? = nil, limit: Int? = nil) async throws -> [Session] {
        var queryItems: [URLQueryItem] = []
        if let status { queryItems.append(URLQueryItem(name: "status", value: status.rawValue)) }
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: String(limit))) }
        return try await client.get("/api/sessions", queryItems: queryItems.isEmpty ? nil : queryItems)
    }

    /// POST /api/sessions - Create a new session
    func createSession(date: Date, location: String?) async throws -> Session {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        var body: [String: Any] = ["date": formatter.string(from: date)]
        if let location, !location.isEmpty { body["location"] = location }
        return try await client.post("/api/sessions", body: body)
    }

    /// GET /api/sessions/[id] - Get a session with full details
    func fetchSessionDetail(id: String) async throws -> SessionDetail {
        try await client.get("/api/sessions/\(id)")
    }

    /// PATCH /api/sessions/[id] - Update a session
    func updateSession(id: String, status: SessionStatus? = nil, location: String? = nil) async throws -> Session {
        var body: [String: Any] = [:]
        if let status { body["status"] = status.rawValue }
        if let location { body["location"] = location }
        return try await client.patch("/api/sessions/\(id)", body: body)
    }

    /// DELETE /api/sessions/[id] - Delete a session
    func deleteSession(id: String) async throws {
        try await client.deleteVoid("/api/sessions/\(id)")
    }

    // MARK: - Attendance

    /// GET /api/sessions/[id]/attendance - Get attendance list
    func fetchAttendance(sessionId: String) async throws -> [Attendance] {
        try await client.get("/api/sessions/\(sessionId)/attendance")
    }

    /// POST /api/sessions/[id]/attendance - Set attendance (bulk)
    func setAttendance(sessionId: String, playerIds: [String]) async throws -> [Attendance] {
        try await client.post("/api/sessions/\(sessionId)/attendance", body: [
            "playerIds": playerIds
        ])
    }

    // MARK: - RSVP

    /// GET /api/sessions/[id]/rsvp - Get RSVPs with summary
    func fetchRSVPs(sessionId: String) async throws -> RSVPResponse {
        try await client.get("/api/sessions/\(sessionId)/rsvp")
    }

    /// POST /api/sessions/[id]/rsvp - Set a player's RSVP
    func setRSVP(sessionId: String, playerId: String, status: RSVPStatus) async throws -> RSVPEntry {
        try await client.post("/api/sessions/\(sessionId)/rsvp", body: [
            "playerId": playerId,
            "status": status.rawValue
        ])
    }

    // MARK: - Games

    /// GET /api/sessions/[id]/games - Get all games for a session
    func fetchGames(sessionId: String) async throws -> [Game] {
        try await client.get("/api/sessions/\(sessionId)/games")
    }

    /// POST /api/sessions/[id]/games - Create a game with ELO updates
    func createGame(sessionId: String, teamAPlayerIds: [String], teamBPlayerIds: [String], scoreA: Int, scoreB: Int) async throws -> Game {
        try await client.post("/api/sessions/\(sessionId)/games", body: [
            "teamAPlayerIds": teamAPlayerIds,
            "teamBPlayerIds": teamBPlayerIds,
            "scoreA": scoreA,
            "scoreB": scoreB
        ])
    }

    // MARK: - Summary

    /// GET /api/sessions/[id]/summary - Get session summary with awards
    func fetchSummary(sessionId: String) async throws -> SessionSummary {
        try await client.get("/api/sessions/\(sessionId)/summary")
    }
}
