import Foundation

// MARK: - Group Service
/// Handles API calls for creating and joining groups.
/// These calls do NOT use the X-Group-Id header since the user
/// hasn't selected a group yet when they call these.
struct GroupService {
    private let client = APIClient.shared

    /// Create a new group with the given name
    func createGroup(name: String) async throws -> Group {
        let group: Group = try await client.post("/api/groups", body: ["name": name])
        return group
    }

    /// Join an existing group by name
    func joinGroup(name: String) async throws -> Group {
        let group: Group = try await client.post("/api/groups/join", body: ["name": name])
        return group
    }

    /// Get group info by ID
    func getGroup(id: String) async throws -> Group {
        return try await client.get("/api/groups/\(id)")
    }
}
