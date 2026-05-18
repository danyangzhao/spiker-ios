import Foundation
import Observation

// MARK: - Players List View Model
@Observable
class PlayersViewModel {
    var players: [Player] = []
    var seasons: [Season] = []
    var selectedSeasonId: String?
    var isLoading = false
    var errorMessage: String?

    // Add player form
    var showAddSheet = false
    var newPlayerName = ""
    var newPlayerEmoji = "🏐"
    var isCreating = false

    private let playerService = PlayerService()
    private let seasonService = SeasonService()

    /// Players sorted by rating (descending)
    var sortedPlayers: [Player] {
        players.sorted { $0.rating > $1.rating }
    }

    var selectedSeasonLabel: String {
        guard let selectedSeason = seasons.first(where: { $0.id == selectedSeasonId }) else {
            return "Current Season"
        }
        return selectedSeason.isActive ? "\(selectedSeason.name) (Current)" : selectedSeason.name
    }

    func loadInitialData() async {
        await loadSeasons()
        await loadPlayers()
    }

    func loadSeasons() async {
        do {
            seasons = try await seasonService.fetchSeasons()
            if selectedSeasonId == nil {
                selectedSeasonId = seasons.first(where: { $0.isActive })?.id ?? seasons.first?.id
            }
        } catch {
            // Keep players view usable even if seasons endpoint fails.
            seasons = []
            selectedSeasonId = nil
        }
    }

    func loadPlayers() async {
        isLoading = true
        errorMessage = nil

        do {
            players = try await playerService.fetchPlayers(seasonId: selectedSeasonId)
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
