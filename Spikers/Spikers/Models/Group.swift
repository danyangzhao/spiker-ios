import Foundation

// MARK: - Group (matches Prisma Group model)
struct Group: Codable, Identifiable {
    let id: String
    let name: String
    let createdAt: String
}
