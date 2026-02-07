import Foundation

// MARK: - Game (from API responses)
struct Game: Codable, Identifiable {
    let id: String
    let sessionId: String
    let scoreA: Int
    let scoreB: Int
    let createdAt: String
    let teamAPlayers: [Player]
    let teamBPlayers: [Player]

    // Optional: included in session detail response
    let video: GameVideoInfo?

    /// Which team won this game
    var winner: String {
        scoreA > scoreB ? "A" : "B"
    }
}

// MARK: - Minimal video info (included in session detail)
struct GameVideoInfo: Codable {
    let id: String
    let status: String
}
