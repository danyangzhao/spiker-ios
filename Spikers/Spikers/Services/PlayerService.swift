import Foundation

// MARK: - Player Service
/// Handles all /api/players endpoints
struct PlayerService {
    private let client = APIClient.shared

    /// GET /api/players - List all players
    func fetchPlayers(activeOnly: Bool = true) async throws -> [Player] {
        try await client.get(
            "/api/players",
            queryItems: [URLQueryItem(name: "activeOnly", value: String(activeOnly))]
        )
    }

    /// POST /api/players - Create a new player
    func createPlayer(name: String, emoji: String) async throws -> Player {
        try await client.post("/api/players", body: [
            "name": name,
            "emoji": emoji
        ])
    }

    /// GET /api/players/[id] - Get a single player with badges
    func fetchPlayer(id: String) async throws -> Player {
        try await client.get("/api/players/\(id)")
    }

    /// PATCH /api/players/[id] - Update a player
    func updatePlayer(id: String, name: String? = nil, emoji: String? = nil, isActive: Bool? = nil) async throws -> Player {
        var body: [String: Any] = [:]
        if let name { body["name"] = name }
        if let emoji { body["emoji"] = emoji }
        if let isActive { body["isActive"] = isActive }
        return try await client.patch("/api/players/\(id)", body: body)
    }

    /// GET /api/players/[id]/stats - Get computed stats for a player
    func fetchPlayerStats(id: String) async throws -> PlayerStatsResponse {
        try await client.get("/api/players/\(id)/stats")
    }
}
