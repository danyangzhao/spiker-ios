import Foundation

// MARK: - Game Service
/// Handles all /api/games endpoints
struct GameService {
    private let client = APIClient.shared

    /// GET /api/games/[id] - Get a single game with details
    func fetchGame(id: String) async throws -> Game {
        try await client.get("/api/games/\(id)")
    }

    /// PATCH /api/games/[id] - Update game scores
    func updateGame(id: String, scoreA: Int, scoreB: Int) async throws -> Game {
        try await client.patch("/api/games/\(id)", body: [
            "scoreA": scoreA,
            "scoreB": scoreB
        ])
    }

    /// DELETE /api/games/[id] - Delete a game (reverts ELO changes)
    func deleteGame(id: String) async throws {
        try await client.deleteVoid("/api/games/\(id)")
    }
}
