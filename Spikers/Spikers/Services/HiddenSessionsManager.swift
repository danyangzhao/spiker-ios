import Foundation

// MARK: - Hidden Sessions Manager
/// Persists a set of hidden session IDs to UserDefaults so "deleted" sessions
/// stay hidden across app launches without actually removing them from the server.
struct HiddenSessionsManager {
    private static let key = "hiddenSessionIds"

    /// The UserDefaults store to use. Defaults to `.standard`.
    /// Tests can pass a custom suite to avoid polluting real app data.
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Returns the set of currently hidden session IDs.
    func hiddenIds() -> Set<String> {
        let array = defaults.stringArray(forKey: Self.key) ?? []
        return Set(array)
    }

    /// Adds a session ID to the hidden set and saves it.
    func hide(_ sessionId: String) {
        var ids = hiddenIds()
        ids.insert(sessionId)
        defaults.set(Array(ids), forKey: Self.key)
    }

    /// Removes a session ID from the hidden set (for future "undo" support).
    func unhide(_ sessionId: String) {
        var ids = hiddenIds()
        ids.remove(sessionId)
        defaults.set(Array(ids), forKey: Self.key)
    }
}
