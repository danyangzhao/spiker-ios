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
    var tournament: TournamentState?

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
    var isSubmittingTournamentGame = false
    var tournamentScoreA = ""
    var tournamentScoreB = ""
    var isSettingUpTournament = false
    var isEndingTournament = false
    var showTournamentSetup = false
    var showTournamentBracket = false

    // Edit Session form state
    var showEditSheet = false
    var editSessionDate = Date()
    var isEditingSession = false

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
            tournament = detail.tournament

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

    // MARK: - Edit Session

    /// Prepares the edit sheet by parsing the current session date
    func prepareEditSession() {
        guard let detail = sessionDetail else { return }

        // Parse the ISO date string back into a Date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: detail.date) {
            editSessionDate = date
        } else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: detail.date) {
                editSessionDate = date
            }
        }

        showEditSheet = true
    }

    /// Saves the edited session date
    func saveEditedSession() async -> Bool {
        isEditingSession = true
        do {
            let _ = try await sessionService.updateSession(id: sessionId, date: editSessionDate)
            showEditSheet = false
            await loadData()
            isEditingSession = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isEditingSession = false
            return false
        }
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

    @discardableResult
    func setAttendance(playerIds: [String]) async -> Bool {
        do {
            let _ = try await sessionService.setAttendance(sessionId: sessionId, playerIds: playerIds)
            await loadData()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Games

    func createGame() async {
        guard let scoreAInt = Int(scoreA), let scoreBInt = Int(scoreB) else {
            errorMessage = "Please enter valid numbers for the scores"
            return
        }

        guard scoreAInt != scoreBInt else {
            errorMessage = "Games cannot end in a tie"
            return
        }

        guard !selectedTeamA.isEmpty && !selectedTeamB.isEmpty else {
            errorMessage = "Please select players for both teams"
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

    /// Generate fair teams by pairing highest and lowest ELO players
    func generateFairTeams() {
        let players = attendingPlayers.sorted { $0.rating > $1.rating }
        guard players.count >= 4 else {
            errorMessage = "Need at least 4 attending players to generate teams"
            return
        }

        guard let strongest = players.first, let weakest = players.last else {
            return
        }
        let middle = players.dropFirst().dropLast()
        guard middle.count >= 2 else {
            errorMessage = "Need at least 4 attending players to generate teams"
            return
        }

        let secondStrongest = middle.first!
        let secondWeakest = middle.last!

        selectedTeamA = [strongest.id, weakest.id]
        selectedTeamB = [secondStrongest.id, secondWeakest.id]
    }

    var canSetupTournament: Bool {
        guard sessionDetail?.status == .IN_PROGRESS else { return false }
        return tournament?.status != .ACTIVE
    }

    var activeTournamentMatch: TournamentMatch? {
        guard let tournament else { return nil }
        return tournament.matches.first { !$0.isComplete }
    }

    func setupTournament(mode: TournamentTeamMode) async {
        isSettingUpTournament = true
        errorMessage = nil
        do {
            tournament = try await sessionService.setupTournament(sessionId: sessionId, mode: mode)
            showTournamentSetup = false
            showTournamentBracket = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isSettingUpTournament = false
    }

    func endTournament() async {
        isEndingTournament = true
        errorMessage = nil
        do {
            tournament = try await sessionService.endTournament(sessionId: sessionId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isEndingTournament = false
    }

    func recordTournamentGame(matchId: String) async {
        guard let tournament else {
            errorMessage = "There's no active tournament for this session"
            return
        }
        guard let scoreA = Int(tournamentScoreA), let scoreB = Int(tournamentScoreB) else {
            errorMessage = "Please enter valid numbers for the scores"
            return
        }
        guard scoreA != scoreB else {
            errorMessage = "Games cannot end in a tie"
            return
        }

        isSubmittingTournamentGame = true
        errorMessage = nil
        do {
            self.tournament = try await sessionService.recordTournamentGame(
                sessionId: sessionId,
                tournamentId: tournament.id,
                matchId: matchId,
                scoreA: scoreA,
                scoreB: scoreB
            )
            tournamentScoreA = ""
            tournamentScoreB = ""
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmittingTournamentGame = false
    }
}
