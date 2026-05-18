import Foundation
import Observation

// MARK: - Player Detail View Model
@Observable
class PlayerDetailViewModel {
    let playerId: String

    var stats: PlayerStatsResponse?
    var seasons: [PlayerStatsSeason] = []
    var selectedSeasonId: String?
    var isLoading = false
    var errorMessage: String?

    private let playerService = PlayerService()

    init(playerId: String) {
        self.playerId = playerId
    }

    func loadStats(seasonId: String? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await playerService.fetchPlayerStats(
                id: playerId,
                seasonId: seasonId ?? selectedSeasonId
            )
            stats = response
            seasons = response.seasons ?? []
            selectedSeasonId = response.selectedSeasonId ?? seasonId
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
