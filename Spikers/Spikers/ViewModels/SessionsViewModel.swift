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

    // Delete session confirmation
    var sessionToDelete: Session? = nil
    var showDeleteConfirmation = false

    // Locally hidden session IDs (persisted in UserDefaults)
    var hiddenSessionIds: Set<String> = []

    private let sessionService = SessionService()
    let hiddenSessionsManager: HiddenSessionsManager

    init(hiddenSessionsManager: HiddenSessionsManager = HiddenSessionsManager()) {
        self.hiddenSessionsManager = hiddenSessionsManager
        self.hiddenSessionIds = hiddenSessionsManager.hiddenIds()
    }

    /// Whether there are any sessions visible (not hidden) to display
    var hasVisibleSessions: Bool {
        sessions.contains { !hiddenSessionIds.contains($0.id) }
    }

    /// Sessions grouped by status, excluding hidden ones
    var liveSessions: [Session] {
        sessions.filter { $0.status == .IN_PROGRESS && !hiddenSessionIds.contains($0.id) }
    }

    var upcomingSessions: [Session] {
        sessions.filter { $0.status == .UPCOMING && !hiddenSessionIds.contains($0.id) }
    }

    var completedSessions: [Session] {
        sessions.filter { $0.status == .COMPLETED && !hiddenSessionIds.contains($0.id) }
    }

    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        // Refresh the hidden IDs so any new hides are picked up
        hiddenSessionIds = hiddenSessionsManager.hiddenIds()

        do {
            sessions = try await sessionService.fetchSessions()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Delete Session (front-end only)

    /// Check if session has games and either delete immediately or prompt for confirmation
    func requestDeleteSession(_ session: Session) {
        let gameCount = session._count?.games ?? 0
        if gameCount > 0 {
            // Session has games — ask the user to confirm first
            sessionToDelete = session
            showDeleteConfirmation = true
        } else {
            // No games — safe to delete right away
            deleteSession(session)
        }
    }

    /// Hide a session persistently (saves to UserDefaults, no API call)
    func deleteSession(_ session: Session) {
        hiddenSessionsManager.hide(session.id)
        hiddenSessionIds.insert(session.id)
        sessions.removeAll { $0.id == session.id }
    }

    /// Called when the user taps "Delete" on the confirmation alert
    func confirmDeleteSession() {
        if let session = sessionToDelete {
            deleteSession(session)
        }
        sessionToDelete = nil
        showDeleteConfirmation = false
    }

    // MARK: - Create Session

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
