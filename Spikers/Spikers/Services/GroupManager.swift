import Foundation
import SwiftUI

// MARK: - Group Manager
/// Persists the current group selection to UserDefaults.
/// The app checks this at launch to decide whether to show onboarding or the main app.
@Observable
final class GroupManager {
    static let shared = GroupManager()

    private let defaults: UserDefaults
    private static let groupIdKey = "currentGroupId"
    private static let groupNameKey = "currentGroupName"
    private static let previousGroupsKey = "previousGroups"

    var currentGroupId: String? {
        didSet { defaults.set(currentGroupId, forKey: Self.groupIdKey) }
    }

    var currentGroupName: String? {
        didSet { defaults.set(currentGroupName, forKey: Self.groupNameKey) }
    }

    /// List of previously joined groups (stored as array of dicts with "id" and "name")
    var previousGroups: [[String: String]] {
        didSet { defaults.set(previousGroups, forKey: Self.previousGroupsKey) }
    }

    var hasGroup: Bool {
        currentGroupId != nil
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.currentGroupId = defaults.string(forKey: Self.groupIdKey)
        self.currentGroupName = defaults.string(forKey: Self.groupNameKey)
        self.previousGroups = (defaults.array(forKey: Self.previousGroupsKey) as? [[String: String]]) ?? []
    }

    /// Save a group as the current group and add it to the history
    func setGroup(_ group: Group) {
        currentGroupId = group.id
        currentGroupName = group.name

        if !previousGroups.contains(where: { $0["id"] == group.id }) {
            previousGroups.append(["id": group.id, "name": group.name])
        }
    }

    /// Switch to a previously joined group
    func switchToGroup(id: String, name: String) {
        currentGroupId = id
        currentGroupName = name
    }

    /// Clear the current group (for testing or sign-out)
    func clearGroup() {
        currentGroupId = nil
        currentGroupName = nil
    }
}
