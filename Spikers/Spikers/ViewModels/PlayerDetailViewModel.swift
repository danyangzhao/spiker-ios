import Foundation
import Observation

// MARK: - Player Detail View Model
@Observable
class PlayerDetailViewModel {
    let playerId: String

    var stats: PlayerStatsResponse?
    var isLoading = false
    var errorMessage: String?

    private let playerService = PlayerService()

    init(playerId: String) {
        self.playerId = playerId
    }

    func loadStats() async {
        isLoading = true
        errorMessage = nil

        do {
            stats = try await playerService.fetchPlayerStats(id: playerId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
