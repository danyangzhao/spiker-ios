import Foundation
import Observation

// MARK: - Game View Model
/// Handles individual game operations (used sparingly)
@Observable
class GameViewModel {
    var game: Game?
    var isLoading = false
    var errorMessage: String?

    private let gameService = GameService()

    func loadGame(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            game = try await gameService.fetchGame(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func deleteGame(id: String) async -> Bool {
        do {
            try await gameService.deleteGame(id: id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
