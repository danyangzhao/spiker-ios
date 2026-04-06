import Foundation
import Observation

// MARK: - Group Messages View Model
@Observable
class GroupMessagesViewModel {
    var messages: [GroupMessage] = []
    var cooldown: PushCooldown?
    var players: [Player] = []

    var isLoading = false
    var errorMessage: String?

    // Compose form state
    var showComposeSheet = false
    var composeTitle = ""
    var composeBody = ""
    var selectedAuthorId: String?
    var isSubmitting = false
    var submitResultMessage: String?

    // Edit state
    var editingMessage: GroupMessage?
    var editTitle = ""
    var editBody = ""
    var isEditing = false

    private let messageService = GroupMessageService()
    private let playerService = PlayerService()

    var groupId: String {
        GroupManager.shared.currentGroupId ?? ""
    }

    /// Human-readable cooldown text, e.g. "Next push available in 5h 30m"
    var cooldownText: String? {
        guard let cooldown, !cooldown.canPush,
              let nextStr = cooldown.nextPushAvailableAt else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let nextDate = formatter.date(from: nextStr) else { return nil }

        let remaining = nextDate.timeIntervalSince(Date())
        guard remaining > 0 else { return nil }

        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60

        if hours > 0 {
            return "Next push available in \(hours)h \(minutes)m"
        } else {
            return "Next push available in \(minutes)m"
        }
    }

    func loadData() async {
        guard !groupId.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            async let messagesResponse = messageService.fetchMessages(groupId: groupId)
            async let fetchedPlayers = playerService.fetchPlayers()

            let (msgResp, plrs) = try await (messagesResponse, fetchedPlayers)
            messages = msgResp.messages
            cooldown = msgResp.cooldown
            players = plrs.filter { $0.isActive }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func createMessage() async -> Bool {
        guard !composeTitle.trimmingCharacters(in: .whitespaces).isEmpty,
              !composeBody.trimmingCharacters(in: .whitespaces).isEmpty,
              let authorId = selectedAuthorId else {
            errorMessage = "Please fill in all fields and select who you are"
            return false
        }

        isSubmitting = true
        submitResultMessage = nil

        do {
            let response = try await messageService.createMessage(
                groupId: groupId,
                title: composeTitle.trimmingCharacters(in: .whitespaces),
                body: composeBody.trimmingCharacters(in: .whitespaces),
                authorId: authorId
            )

            if response.pushSent {
                submitResultMessage = "Message posted and push notification sent!"
            } else {
                submitResultMessage = "Message posted! Push notification skipped (cooldown active)."
            }

            cooldown = response.cooldown

            // Reset form
            composeTitle = ""
            composeBody = ""
            selectedAuthorId = nil
            showComposeSheet = false

            await loadData()
            isSubmitting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
            return false
        }
    }

    func startEditing(_ message: GroupMessage) {
        editingMessage = message
        editTitle = message.title
        editBody = message.body
    }

    func saveEdit() async -> Bool {
        guard let message = editingMessage,
              !editTitle.trimmingCharacters(in: .whitespaces).isEmpty,
              !editBody.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Title and body are required"
            return false
        }

        isEditing = true

        do {
            let _ = try await messageService.updateMessage(
                groupId: groupId,
                messageId: message.id,
                title: editTitle.trimmingCharacters(in: .whitespaces),
                body: editBody.trimmingCharacters(in: .whitespaces)
            )

            editingMessage = nil
            editTitle = ""
            editBody = ""

            await loadData()
            isEditing = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isEditing = false
            return false
        }
    }
}
