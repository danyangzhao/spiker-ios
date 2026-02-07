import SwiftUI

// MARK: - Content View (Root Tab Navigation)
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
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
    }
}

#Preview {
    ContentView()
}
