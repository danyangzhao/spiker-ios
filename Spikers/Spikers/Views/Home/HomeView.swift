import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.players.isEmpty {
                    LoadingView(message: "Loading dashboard...")
                } else if let error = viewModel.errorMessage, viewModel.players.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadData() }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Live Session Alert
                            if let live = viewModel.liveSession {
                                LiveSessionBanner(session: live)
                            }

                            // Upcoming Session
                            if let next = viewModel.nextSession {
                                UpcomingSessionCard(session: next)
                            }

                            // Leaderboard
                            LeaderboardSection(players: viewModel.leaderboard)

                            // Recent Sessions
                            if !viewModel.recentSessions.isEmpty {
                                RecentSessionsSection(sessions: viewModel.recentSessions)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadData()
                    }
                }
            }
            .navigationTitle("Spikers")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Live Session Banner
struct LiveSessionBanner: View {
    let session: Session

    var body: some View {
        NavigationLink(destination: SessionDetailView(sessionId: session.id)) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Live Session")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    if let location = session.location {
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }
}

// MARK: - Upcoming Session Card
struct UpcomingSessionCard: View {
    let session: Session

    var body: some View {
        NavigationLink(destination: SessionDetailView(sessionId: session.id)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Next Session")
                        .font(.headline)
                        .foregroundColor(AppTheme.foreground)
                    Spacer()
                    StatusBadge(status: .UPCOMING)
                }

                Text(formatDate(session.date))
                    .font(.subheadline)
                    .foregroundColor(AppTheme.accent)

                if let location = session.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.secondaryText)
                }

                if let count = session._count {
                    HStack(spacing: 12) {
                        Label("\(count.games) games", systemImage: "sportscourt")
                        Label("\(count.attendances) players", systemImage: "person.2")
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                }
            }
            .cardStyle()
        }
    }
}

// MARK: - Leaderboard Section
struct LeaderboardSection: View {
    let players: [Player]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            if players.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: "No Players Yet",
                    message: "Add players to see the leaderboard"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                        NavigationLink(destination: PlayerDetailView(playerId: player.id)) {
                            HStack(spacing: 12) {
                                // Rank
                                Text("#\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(index == 0 ? AppTheme.accent : AppTheme.secondaryText)
                                    .frame(width: 28)

                                Text(player.emoji)
                                    .font(.title3)

                                Text(player.name)
                                    .font(.body)
                                    .foregroundColor(AppTheme.foreground)

                                Spacer()

                                Text("\(player.rating)")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.accent)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                        }

                        if index < players.count - 1 {
                            Divider()
                                .background(AppTheme.card03)
                        }
                    }
                }
                .background(AppTheme.card)
                .cornerRadius(16)
            }
        }
    }
}

// MARK: - Recent Sessions Section
struct RecentSessionsSection: View {
    let sessions: [Session]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            VStack(spacing: 8) {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionDetailView(sessionId: session.id)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatDate(session.date))
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.foreground)

                                if let location = session.location {
                                    Text(location)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }

                            Spacer()

                            if let count = session._count {
                                Text("\(count.games) games")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(12)
                        .background(AppTheme.card)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Date Formatting Helper
/// Formats an ISO date string for display
func formatDate(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    // Try with fractional seconds first, then without
    guard let date = formatter.date(from: dateString) ?? {
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }() else {
        return dateString
    }

    let displayFormatter = DateFormatter()
    displayFormatter.dateFormat = "EEE, MMM d 'at' h:mm a"
    displayFormatter.timeZone = .current
    return displayFormatter.string(from: date)
}

/// Formats an ISO date string for shorter display
func formatDateShort(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    guard let date = formatter.date(from: dateString) ?? {
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }() else {
        return dateString
    }

    let displayFormatter = DateFormatter()
    displayFormatter.dateFormat = "MMM d, yyyy"
    displayFormatter.timeZone = .current
    return displayFormatter.string(from: date)
}
