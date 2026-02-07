import Foundation
import Observation

// MARK: - Session Detail View Model
@Observable
class SessionDetailViewModel {
    let sessionId: String

    var sessionDetail: SessionDetail?
    var rsvpResponse: RSVPResponse?
    var summary: SessionSummary?
    var allPlayers: [Player] = []

    var isLoading = false
    var errorMessage: String?
    var isUpdatingStatus = false

    // Add Game form state
    var showAddGame = false
    var selectedTeamA: Set<String> = []
    var selectedTeamB: Set<String> = []
    var scoreA = ""
    var scoreB = ""
    var isCreatingGame = false

    private let sessionService = SessionService()
    private let gameService = GameService()
    private let playerService = PlayerService()

    init(sessionId: String) {
        self.sessionId = sessionId
    }

    /// Available players for the game (from attendance)
    var attendingPlayers: [Player] {
        guard let detail = sessionDetail else { return [] }
        return detail.attendances.filter { $0.present }.map { $0.player }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let detailTask = sessionService.fetchSessionDetail(id: sessionId)
            async let playersTask = playerService.fetchPlayers()

            let (detail, players) = try await (detailTask, playersTask)
            sessionDetail = detail
            allPlayers = players

            // Load RSVP data
            rsvpResponse = try await sessionService.fetchRSVPs(sessionId: sessionId)

            // Load summary if completed or in progress
            if detail.status == .COMPLETED || detail.status == .IN_PROGRESS {
                summary = try? await sessionService.fetchSummary(sessionId: sessionId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Status Management

    func startSession() async {
        isUpdatingStatus = true
        do {
            let _ = try await sessionService.updateSession(id: sessionId, status: .IN_PROGRESS)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdatingStatus = false
    }

    func completeSession() async {
        isUpdatingStatus = true
        do {
            let _ = try await sessionService.updateSession(id: sessionId, status: .COMPLETED)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isUpdatingStatus = false
    }

    // MARK: - RSVP

    func setRSVP(playerId: String, status: RSVPStatus) async {
        do {
            let _ = try await sessionService.setRSVP(sessionId: sessionId, playerId: playerId, status: status)
            rsvpResponse = try await sessionService.fetchRSVPs(sessionId: sessionId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Attendance

    func setAttendance(playerIds: [String]) async {
        do {
            let _ = try await sessionService.setAttendance(sessionId: sessionId, playerIds: playerIds)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Games

    func createGame() async {
        guard let scoreAInt = Int(scoreA), let scoreBInt = Int(scoreB) else {
            errorMessage = "Scores must be numbers"
            return
        }

        guard scoreAInt != scoreBInt else {
            errorMessage = "Games cannot end in a tie"
            return
        }

        guard !selectedTeamA.isEmpty && !selectedTeamB.isEmpty else {
            errorMessage = "Both teams need players"
            return
        }

        isCreatingGame = true

        do {
            let _ = try await sessionService.createGame(
                sessionId: sessionId,
                teamAPlayerIds: Array(selectedTeamA),
                teamBPlayerIds: Array(selectedTeamB),
                scoreA: scoreAInt,
                scoreB: scoreBInt
            )

            // Reset form
            selectedTeamA = []
            selectedTeamB = []
            scoreA = ""
            scoreB = ""
            showAddGame = false

            // Reload
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }

        isCreatingGame = false
    }

    func deleteGame(id: String) async {
        do {
            try await gameService.deleteGame(id: id)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Generate random teams from attending players
    func generateRandomTeams() {
        let players = attendingPlayers
        guard players.count >= 4 else {
            errorMessage = "Need at least 4 attending players to generate teams"
            return
        }

        let shuffled = players.shuffled()
        selectedTeamA = Set(shuffled.prefix(2).map { $0.id })
        selectedTeamB = Set(shuffled.dropFirst(2).prefix(2).map { $0.id })
    }
}
