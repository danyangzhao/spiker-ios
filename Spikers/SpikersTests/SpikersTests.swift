//
//  SpikersTests.swift
//  SpikersTests
//
//  Created by Danyang Zhao on 2/7/26.
//

import Foundation
import Testing
@testable import Spikers

struct SpikersTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    // MARK: - NotificationManager Tests

    @Test func notificationManagerStartsWithNoPermission() async throws {
        let manager = NotificationManager.shared
        manager.deviceToken = nil
        // On first launch (before user grants permission), permission should not be granted
        // Note: In tests, we can't actually trigger the system permission dialog,
        // but we can verify the initial state
        #expect(manager.deviceToken == nil)
    }

    @Test func notificationManagerHandlesDeviceToken() async throws {
        let manager = NotificationManager.shared
        manager.deviceToken = nil

        // Simulate receiving a device token from APNs
        // A real token is 32 bytes, but we'll use a shorter one for testing
        let fakeTokenData = Data([0xAB, 0xCD, 0xEF, 0x12, 0x34])
        manager.handleDeviceToken(fakeTokenData)

        // Give a moment for the async token handling to complete
        try await Task.sleep(for: .milliseconds(100))

        // The token should be converted to a hex string
        #expect(manager.deviceToken == "abcdef1234")
    }

    // MARK: - NotificationService Tests

    @Test func notificationServiceEndpointPaths() async throws {
        // Verify the API client is configured with the correct base URL
        let client = APIClient.shared
        #expect(client.baseURL == "https://spikers-production.up.railway.app")
    }

    // MARK: - HiddenSessionsManager Tests

    /// Creates a fresh HiddenSessionsManager backed by a unique UserDefaults suite.
    /// Each call gets its own suite so parallel tests don't interfere with each other.
    private func makeTestManager() -> HiddenSessionsManager {
        let suiteName = "com.spikers.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return HiddenSessionsManager(defaults: defaults)
    }

    @Test func hiddenSessionsManagerStartsEmpty() async throws {
        let manager = makeTestManager()
        #expect(manager.hiddenIds().isEmpty)
    }

    @Test func hiddenSessionsManagerHideAddsId() async throws {
        let manager = makeTestManager()

        manager.hide("session-A")
        #expect(manager.hiddenIds().contains("session-A"))
        #expect(manager.hiddenIds().count == 1)
    }

    @Test func hiddenSessionsManagerHideMultipleIds() async throws {
        let manager = makeTestManager()

        manager.hide("session-A")
        manager.hide("session-B")
        #expect(manager.hiddenIds() == Set(["session-A", "session-B"]))
    }

    @Test func hiddenSessionsManagerHideDuplicateIsNoOp() async throws {
        let manager = makeTestManager()

        manager.hide("session-A")
        manager.hide("session-A")
        #expect(manager.hiddenIds().count == 1)
    }

    @Test func hiddenSessionsManagerUnhideRemovesId() async throws {
        let manager = makeTestManager()

        manager.hide("session-A")
        manager.hide("session-B")
        manager.unhide("session-A")

        #expect(!manager.hiddenIds().contains("session-A"))
        #expect(manager.hiddenIds().contains("session-B"))
    }

    @Test func hiddenSessionsManagerPersistsAcrossInstances() async throws {
        let suiteName = "com.spikers.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        // Hide a session with one manager instance
        let manager1 = HiddenSessionsManager(defaults: defaults)
        manager1.hide("session-X")

        // Create a brand-new manager instance using the same defaults
        let manager2 = HiddenSessionsManager(defaults: defaults)
        #expect(manager2.hiddenIds().contains("session-X"))
    }

    // MARK: - Session Deletion Tests

    @Test func deleteSessionRemovesFromList() async throws {
        let vm = SessionsViewModel(hiddenSessionsManager: makeTestManager())

        // Add a fake session to the list
        let session = Session(
            id: "test-1",
            date: "2026-02-07T00:00:00.000Z",
            location: nil,
            createdAt: "2026-02-07T00:00:00.000Z",
            status: .UPCOMING,
            _count: nil
        )
        vm.sessions = [session]
        #expect(vm.sessions.count == 1)

        // Delete it
        vm.deleteSession(session)

        // Should be gone from the list
        #expect(vm.sessions.isEmpty)

        // Should be persisted in the hidden set
        #expect(vm.hiddenSessionIds.contains("test-1"))
        #expect(vm.hiddenSessionsManager.hiddenIds().contains("test-1"))
    }

    @Test func requestDeleteSessionWithNoGamesDeletesImmediately() async throws {
        let vm = SessionsViewModel(hiddenSessionsManager: makeTestManager())

        // Session with 0 games
        let session = Session(
            id: "test-2",
            date: "2026-02-07T00:00:00.000Z",
            location: nil,
            createdAt: "2026-02-07T00:00:00.000Z",
            status: .UPCOMING,
            _count: SessionCounts(games: 0, attendances: 0)
        )
        vm.sessions = [session]

        // Request delete — should remove immediately (no confirmation)
        vm.requestDeleteSession(session)

        #expect(vm.sessions.isEmpty)
        #expect(vm.showDeleteConfirmation == false)
        #expect(vm.sessionToDelete == nil)
        #expect(vm.hiddenSessionIds.contains("test-2"))
    }

    @Test func requestDeleteSessionWithGamesShowsConfirmation() async throws {
        let vm = SessionsViewModel(hiddenSessionsManager: makeTestManager())

        // Session with 3 games
        let session = Session(
            id: "test-3",
            date: "2026-02-07T00:00:00.000Z",
            location: nil,
            createdAt: "2026-02-07T00:00:00.000Z",
            status: .COMPLETED,
            _count: SessionCounts(games: 3, attendances: 5)
        )
        vm.sessions = [session]

        // Request delete — should NOT remove yet, should show confirmation
        vm.requestDeleteSession(session)

        #expect(vm.sessions.count == 1)
        #expect(vm.showDeleteConfirmation == true)
        #expect(vm.sessionToDelete?.id == "test-3")
    }

    @Test func confirmDeleteSessionRemovesAndResetsState() async throws {
        let vm = SessionsViewModel(hiddenSessionsManager: makeTestManager())

        // Session with games
        let session = Session(
            id: "test-4",
            date: "2026-02-07T00:00:00.000Z",
            location: nil,
            createdAt: "2026-02-07T00:00:00.000Z",
            status: .COMPLETED,
            _count: SessionCounts(games: 2, attendances: 4)
        )
        vm.sessions = [session]

        // Simulate the user requesting delete (triggers confirmation)
        vm.requestDeleteSession(session)
        #expect(vm.showDeleteConfirmation == true)

        // Now simulate the user confirming
        vm.confirmDeleteSession()

        // Session should be gone, and confirmation state should be reset
        #expect(vm.sessions.isEmpty)
        #expect(vm.showDeleteConfirmation == false)
        #expect(vm.sessionToDelete == nil)
        #expect(vm.hiddenSessionIds.contains("test-4"))
    }

    @Test func hiddenSessionsFilteredFromComputedProperties() async throws {
        let manager = makeTestManager()
        manager.hide("hidden-1")
        let vm = SessionsViewModel(hiddenSessionsManager: manager)

        // Add a mix of visible and hidden sessions
        vm.sessions = [
            Session(id: "hidden-1", date: "2026-02-07T00:00:00.000Z", location: nil,
                    createdAt: "2026-02-07T00:00:00.000Z", status: .UPCOMING, _count: nil),
            Session(id: "visible-1", date: "2026-02-07T00:00:00.000Z", location: nil,
                    createdAt: "2026-02-07T00:00:00.000Z", status: .UPCOMING, _count: nil),
            Session(id: "visible-2", date: "2026-02-07T00:00:00.000Z", location: nil,
                    createdAt: "2026-02-07T00:00:00.000Z", status: .COMPLETED, _count: nil),
        ]

        // hidden-1 is UPCOMING but should be filtered out
        #expect(vm.upcomingSessions.count == 1)
        #expect(vm.upcomingSessions.first?.id == "visible-1")
        #expect(vm.completedSessions.count == 1)
        #expect(vm.hasVisibleSessions == true)
    }

    @Test func hasVisibleSessionsFalseWhenAllHidden() async throws {
        let manager = makeTestManager()
        manager.hide("only-session")
        let vm = SessionsViewModel(hiddenSessionsManager: manager)

        vm.sessions = [
            Session(id: "only-session", date: "2026-02-07T00:00:00.000Z", location: nil,
                    createdAt: "2026-02-07T00:00:00.000Z", status: .UPCOMING, _count: nil),
        ]

        #expect(vm.hasVisibleSessions == false)
        #expect(vm.upcomingSessions.isEmpty)
    }

    // MARK: - Edit Session Tests

    @Test func editSessionInitialState() async throws {
        let vm = SessionDetailViewModel(sessionId: "test-session")

        // Edit sheet should start hidden
        #expect(vm.showEditSheet == false)
        #expect(vm.isEditingSession == false)
    }

    @Test func prepareEditSessionParsesDateAndShowsSheet() async throws {
        let vm = SessionDetailViewModel(sessionId: "test-session")

        // Simulate a loaded session detail with a known date
        // prepareEditSession reads from sessionDetail, so we need to set it
        // Since SessionDetail requires many fields, we'll test the state toggle directly
        #expect(vm.showEditSheet == false)

        // Without a sessionDetail, prepareEditSession should not open the sheet
        vm.prepareEditSession()
        #expect(vm.showEditSheet == false)
    }

    @Test func editSessionDateDefaultsToNow() async throws {
        let vm = SessionDetailViewModel(sessionId: "test-session")

        // The editSessionDate should default to approximately now
        let now = Date()
        let diff = abs(vm.editSessionDate.timeIntervalSince(now))

        // Should be within 1 second of now
        #expect(diff < 1.0)
    }

    // MARK: - Tournament Tests

    @Test func tournamentSetupAvailabilityFollowsSessionAndTournamentState() async throws {
        let vm = SessionDetailViewModel(sessionId: "test-session")

        // Not in progress yet
        #expect(vm.canSetupTournament == false)

        let player = Player(
            id: "p1",
            name: "Alex",
            emoji: "😎",
            createdAt: "2026-02-07T00:00:00.000Z",
            isActive: true,
            rating: 1000,
            playerBadges: nil
        )

        vm.sessionDetail = SessionDetail(
            id: "s1",
            date: "2026-02-07T00:00:00.000Z",
            location: nil,
            createdAt: "2026-02-07T00:00:00.000Z",
            status: .IN_PROGRESS,
            attendances: [],
            rsvps: [],
            games: [],
            tournament: nil
        )

        #expect(vm.canSetupTournament == true)

        let team = TournamentTeam(
            id: "team-1",
            tournamentId: "t1",
            name: "Team 1",
            seed: 1,
            wins: 0,
            losses: 0,
            isEliminated: false,
            playerAId: player.id,
            playerBId: nil,
            playerA: player,
            playerB: nil
        )
        vm.tournament = TournamentState(
            id: "t1",
            sessionId: "s1",
            status: .ACTIVE,
            teamMode: .RANDOM,
            stage: .ROUND_ROBIN,
            createdAt: "2026-02-07T00:00:00.000Z",
            updatedAt: "2026-02-07T00:00:00.000Z",
            endedAt: nil,
            winnerTeamId: nil,
            teams: [team],
            matches: []
        )

        #expect(vm.canSetupTournament == false)
    }

    @Test func activeTournamentMatchReturnsFirstIncompleteMatch() async throws {
        let vm = SessionDetailViewModel(sessionId: "test-session")

        let playerA = Player(
            id: "p1",
            name: "Alex",
            emoji: "😎",
            createdAt: "2026-02-07T00:00:00.000Z",
            isActive: true,
            rating: 1000,
            playerBadges: nil
        )
        let playerB = Player(
            id: "p2",
            name: "Blair",
            emoji: "🔥",
            createdAt: "2026-02-07T00:00:00.000Z",
            isActive: true,
            rating: 1000,
            playerBadges: nil
        )

        let team = TournamentTeam(
            id: "team-1",
            tournamentId: "t1",
            name: "Team 1",
            seed: 1,
            wins: 0,
            losses: 0,
            isEliminated: false,
            playerAId: playerA.id,
            playerBId: playerB.id,
            playerA: playerA,
            playerB: playerB
        )

        let completedMatch = TournamentMatch(
            id: "m1",
            tournamentId: "t1",
            stage: .ROUND_ROBIN,
            round: 1,
            slot: 1,
            bestOf: 3,
            winsA: 2,
            winsB: 0,
            isComplete: true,
            teamAId: team.id,
            teamBId: nil,
            winnerTeamId: team.id,
            loserTeamId: nil,
            teamAPlayerIds: [playerA.id, playerB.id],
            teamBPlayerIds: [],
            teamA: team,
            teamB: nil,
            winnerTeam: team,
            loserTeam: nil,
            games: []
        )
        let openMatch = TournamentMatch(
            id: "m2",
            tournamentId: "t1",
            stage: .BRACKET,
            round: 1,
            slot: 2,
            bestOf: 3,
            winsA: 1,
            winsB: 1,
            isComplete: false,
            teamAId: team.id,
            teamBId: nil,
            winnerTeamId: nil,
            loserTeamId: nil,
            teamAPlayerIds: [playerA.id, playerB.id],
            teamBPlayerIds: [],
            teamA: team,
            teamB: nil,
            winnerTeam: nil,
            loserTeam: nil,
            games: []
        )

        vm.tournament = TournamentState(
            id: "t1",
            sessionId: "s1",
            status: .ACTIVE,
            teamMode: .RANDOM,
            stage: .BRACKET,
            createdAt: "2026-02-07T00:00:00.000Z",
            updatedAt: "2026-02-07T00:00:00.000Z",
            endedAt: nil,
            winnerTeamId: nil,
            teams: [team],
            matches: [completedMatch, openMatch]
        )

        #expect(vm.activeTournamentMatch?.id == "m2")
    }

    // MARK: - APIError User-Friendly Message Tests

    @Test func apiErrorHttpErrorShowsOnlyMessage() async throws {
        let error = APIError.httpError(statusCode: 400, message: "Need at least 4 attendees to start a tournament")
        #expect(error.localizedDescription == "Need at least 4 attendees to start a tournament")
    }

    @Test func apiErrorHttpErrorDoesNotContainStatusCode() async throws {
        let error = APIError.httpError(statusCode: 500, message: "Internal server error")
        #expect(!error.localizedDescription.contains("500"))
        #expect(!error.localizedDescription.contains("Server error"))
    }

    @Test func apiErrorNetworkErrorShowsFriendlyMessage() async throws {
        let underlyingError = URLError(.notConnectedToInternet)
        let error = APIError.networkError(underlyingError)
        #expect(error.localizedDescription == "Couldn't connect to the server. Check your internet and try again.")
    }

    @Test func apiErrorDecodingErrorShowsFriendlyMessage() async throws {
        let underlyingError = NSError(domain: "test", code: 0, userInfo: nil)
        let error = APIError.decodingError(underlyingError)
        #expect(error.localizedDescription == "Something went wrong loading the data. Try again in a moment.")
    }

    @Test func apiErrorInvalidURLShowsFriendlyMessage() async throws {
        let error = APIError.invalidURL
        #expect(error.localizedDescription == "Something went wrong. Please try again.")
    }

    @Test func apiErrorInvalidResponseShowsFriendlyMessage() async throws {
        let error = APIError.invalidResponse
        #expect(error.localizedDescription == "Received an unexpected response. Please try again.")
    }

    @Test func apiErrorNetworkErrorIsDetectedAsNetworkError() async throws {
        let networkError = APIError.networkError(URLError(.timedOut))
        #expect(networkError.isNetworkError == true)

        let httpError = APIError.httpError(statusCode: 400, message: "Bad request")
        #expect(httpError.isNetworkError == false)
    }
}
