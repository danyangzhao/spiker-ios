import Foundation

// MARK: - Season Service
/// Handles all /api/seasons endpoints.
struct SeasonService {
    private let client = APIClient.shared

    /// GET /api/seasons - List all seasons in current group.
    func fetchSeasons() async throws -> [Season] {
        try await client.get("/api/seasons")
    }

    /// GET /api/seasons/[id] - Get season detail including standings + sessions + badges.
    func fetchSeasonDetail(id: String) async throws -> SeasonDetail {
        try await client.get("/api/seasons/\(id)")
    }

    /// POST /api/seasons - Start a new season and reset carried players.
    func startSeason(name: String?, carryOverPlayerIds: [String]) async throws -> Season {
        var body: [String: Any] = [
            "carryOverPlayerIds": carryOverPlayerIds
        ]
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            body["name"] = name.trimmingCharacters(in: .whitespaces)
        }
        return try await client.post("/api/seasons", body: body)
    }
}
