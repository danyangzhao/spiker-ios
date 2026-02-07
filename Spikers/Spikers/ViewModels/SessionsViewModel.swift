import Foundation
import Observation

// MARK: - Sessions List View Model
@Observable
class SessionsViewModel {
    var sessions: [Session] = []
    var isLoading = false
    var errorMessage: String?

    // Create session form
    var showCreateSheet = false
    var newSessionDate = Date()
    var newSessionLocation = ""
    var isCreating = false

    private let sessionService = SessionService()

    /// Sessions grouped by status
    var liveSessions: [Session] {
        sessions.filter { $0.status == .IN_PROGRESS }
    }

    var upcomingSessions: [Session] {
        sessions.filter { $0.status == .UPCOMING }
    }

    var completedSessions: [Session] {
        sessions.filter { $0.status == .COMPLETED }
    }

    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            sessions = try await sessionService.fetchSessions()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createSession() async -> Bool {
        isCreating = true

        do {
            let _ = try await sessionService.createSession(
                date: newSessionDate,
                location: newSessionLocation.isEmpty ? nil : newSessionLocation
            )
            // Reset form
            newSessionDate = Date()
            newSessionLocation = ""
            showCreateSheet = false

            // Reload
            await loadSessions()
            isCreating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isCreating = false
            return false
        }
    }
}
