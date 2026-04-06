import Foundation

// MARK: - Group Message Author (subset of Player)
struct GroupMessageAuthor: Codable, Identifiable {
    let id: String
    let name: String
    let emoji: String
}

// MARK: - Group Message (matches Prisma GroupMessage model)
struct GroupMessage: Codable, Identifiable {
    let id: String
    let title: String
    let body: String
    let createdAt: String
    let updatedAt: String
    let pushSentAt: String?
    let groupId: String
    let authorId: String
    let author: GroupMessageAuthor
}

// MARK: - Push Cooldown Info
struct PushCooldown: Codable {
    let canPush: Bool
    let nextPushAvailableAt: String?
}

// MARK: - API Responses
struct GroupMessagesResponse: Codable {
    let messages: [GroupMessage]
    let cooldown: PushCooldown
}

struct GroupMessageCreateResponse: Codable {
    let message: GroupMessage
    let pushSent: Bool
    let cooldown: PushCooldown
}

struct GroupMessageUpdateResponse: Codable {
    let message: GroupMessage
    let pushSent: Bool
}
