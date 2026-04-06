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

                Tab("Players", systemImage: "person.2.fill", value: 2) {
                    PlayersListView()
                }
            }
            .tint(AppTheme.accent)
            .task {
                if !NotificationManager.shared.isPermissionGranted {
                    await NotificationManager.shared.requestPermission()
                }
            }
        } else {
            OnboardingView()
        }
    }
}

#Preview {
    ContentView()
}
