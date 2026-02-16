import Foundation
import Observation

// MARK: - Players List View Model
@Observable
class PlayersViewModel {
    var players: [Player] = []
    var isLoading = false
    var errorMessage: String?

    // Add player form
    var showAddSheet = false
    var newPlayerName = ""
    var newPlayerEmoji = "🏐"
    var isCreating = false

    private let playerService = PlayerService()

    /// Players sorted by rating (descending)
    var sortedPlayers: [Player] {
        players.sorted { $0.rating > $1.rating }
    }

    func loadPlayers() async {
        isLoading = true
        errorMessage = nil

        do {
            players = try await playerService.fetchPlayers()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createPlayer() async -> Bool {
        guard !newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a name for the player"
            return false
        }

        isCreating = true

        do {
            let _ = try await playerService.createPlayer(
                name: newPlayerName.trimmingCharacters(in: .whitespaces),
                emoji: newPlayerEmoji
            )

            // Reset form
            newPlayerName = ""
            newPlayerEmoji = "🏐"
            showAddSheet = false

            // Reload
            await loadPlayers()
            isCreating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isCreating = false
            return false
        }
    }
}
