import SwiftUI

// MARK: - Content View (Root Tab Navigation)
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var groupManager = GroupManager.shared

    var body: some View {
        if groupManager.hasGroup {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: 0) {
                    HomeView()
                }

                Tab("Sessions", systemImage: "calendar", value: 1) {
                    SessionsListView()
                }

                Tab("Messages", systemImage: "megaphone", value: 2) {
                    GroupMessagesView()
                }

                Tab("Players", systemImage: "person.2.fill", value: 3) {
                    PlayersListView()
                }
            }
            .tint(AppTheme.accent)
            .onReceive(NotificationCenter.default.publisher(for: .didReceiveSessionNotification)) { _ in
                selectedTab = 1
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
