import Foundation
import Observation

// MARK: - Home View Model
@Observable
class HomeViewModel {
    var players: [Player] = []
    var liveSessions: [Session] = []
    var upcomingSessions: [Session] = []
    var recentSessions: [Session] = []
    var isLoading = false
    var errorMessage: String?

    private let playerService = PlayerService()
    private let sessionService = SessionService()

    /// Top 5 players sorted by rating (descending)
    var leaderboard: [Player] {
        Array(players.sorted { $0.rating > $1.rating }.prefix(5))
    }

    /// The first upcoming session (soonest)
    var nextSession: Session? {
        upcomingSessions.first
    }

    /// The first live session (if any)
    var liveSession: Session? {
        liveSessions.first
    }

    /// Load all data for the home screen
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch all data in parallel
            async let playersTask = playerService.fetchPlayers()
            async let liveTask = sessionService.fetchSessions(status: .IN_PROGRESS)
            async let upcomingTask = sessionService.fetchSessions(status: .UPCOMING)
            async let recentTask = sessionService.fetchSessions(status: .COMPLETED, limit: 3)

            let (fetchedPlayers, fetchedLive, fetchedUpcoming, fetchedRecent) =
                try await (playersTask, liveTask, upcomingTask, recentTask)

            players = fetchedPlayers
            liveSessions = fetchedLive
            upcomingSessions = fetchedUpcoming
            recentSessions = fetchedRecent
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
