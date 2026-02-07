import SwiftUI

// MARK: - Player Detail View
struct PlayerDetailView: View {
    let playerId: String
    @State private var viewModel: PlayerDetailViewModel
    @State private var selectedTab = 0

    init(playerId: String) {
        self.playerId = playerId
        self._viewModel = State(initialValue: PlayerDetailViewModel(playerId: playerId))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.stats == nil {
                LoadingView(message: "Loading player...")
            } else if let error = viewModel.errorMessage, viewModel.stats == nil {
                ErrorView(message: error) {
                    Task { await viewModel.loadStats() }
                }
            } else if let stats = viewModel.stats {
                VStack(spacing: 0) {
                    // Player header
                    PlayerHeader(player: stats.player, streak: stats.attendanceStreak)

                    // Tab picker
                    Picker("Section", selection: $selectedTab) {
                        Text("Stats").tag(0)
                        Text("Chemistry").tag(1)
                        Text("Badges").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // Tab content
                    ScrollView {
                        switch selectedTab {
                        case 0:
                            PlayerStatsTab(stats: stats.lifetimeStats)
                        case 1:
                            PlayerChemistryTab(
                                partners: stats.partnerChemistry,
                                nemeses: stats.nemesisOpponents
                            )
                        case 2:
                            BadgeGrid(badges: stats.badges)
                                .padding()
                        default:
                            EmptyView()
                        }
                    }
                    .refreshable {
                        await viewModel.loadStats()
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadStats()
        }
    }
}

// MARK: - Player Header
struct PlayerHeader: View {
    let player: PlayerBasicInfo
    let streak: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(player.emoji)
                .font(.system(size: 56))

            Text(player.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.foreground)

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(player.rating)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accent)
                    Text("Rating")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }

                if streak > 0 {
                    VStack(spacing: 2) {
                        Text("\(streak)🔥")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.foreground)
                        Text("Streak")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.card)
    }
}

// MARK: - Stats Tab
struct PlayerStatsTab: View {
    let stats: LifetimeStats

    var body: some View {
        VStack(spacing: 12) {
            // Main stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                StatCard(
                    label: "Games Played",
                    value: "\(stats.gamesPlayed)"
                )
                StatCard(
                    label: "Win Rate",
                    value: stats.gamesPlayed > 0
                        ? "\(Int(stats.winRate * 100))%"
                        : "-",
                    valueColor: stats.winRate >= 0.5 ? AppTheme.win : AppTheme.loss
                )
                StatCard(
                    label: "Wins",
                    value: "\(stats.wins)",
                    valueColor: AppTheme.win
                )
                StatCard(
                    label: "Losses",
                    value: "\(stats.losses)",
                    valueColor: AppTheme.loss
                )
            }

            // Additional stats
            VStack(spacing: 8) {
                StatRow(label: "Sessions Attended", value: "\(stats.sessionsAttended)")
                Divider().background(AppTheme.card03)
                StatRow(label: "Points For", value: "\(stats.pointsFor)")
                Divider().background(AppTheme.card03)
                StatRow(label: "Points Against", value: "\(stats.pointsAgainst)")
                Divider().background(AppTheme.card03)
                StatRow(
                    label: "Avg Point Diff",
                    value: String(format: "%+.1f", stats.avgPointDiff),
                    valueColor: stats.avgPointDiff >= 0 ? AppTheme.win : AppTheme.loss
                )
            }
            .cardStyle()
        }
        .padding()
    }
}

// MARK: - Chemistry Tab
struct PlayerChemistryTab: View {
    let partners: [PartnerStat]
    let nemeses: [NemesisStat]

    var body: some View {
        VStack(spacing: 20) {
            // Best Partners
            VStack(alignment: .leading, spacing: 12) {
                Text("Best Partners")
                    .font(.headline)
                    .foregroundColor(AppTheme.foreground)

                if partners.isEmpty {
                    Text("Play more games to see partner stats (min 3 games)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .cardStyle()
                } else {
                    ForEach(partners) { partner in
                        HStack {
                            Text(partner.partnerEmoji)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(partner.partnerName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.foreground)
                                Text("\(partner.gamesPlayed) games together")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            Spacer()
                            Text("\(Int(partner.winRate * 100))%")
                                .font(.headline)
                                .foregroundColor(partner.winRate >= 0.5 ? AppTheme.win : AppTheme.loss)
                        }
                        .cardStyle()
                    }
                }
            }

            // Toughest Opponents
            VStack(alignment: .leading, spacing: 12) {
                Text("Toughest Opponents")
                    .font(.headline)
                    .foregroundColor(AppTheme.foreground)

                if nemeses.isEmpty {
                    Text("Play more games to see opponent stats (min 3 games)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .cardStyle()
                } else {
                    ForEach(nemeses) { nemesis in
                        HStack {
                            HStack(spacing: -4) {
                                ForEach(Array(nemesis.opponentEmojis.enumerated()), id: \.offset) { _, emoji in
                                    Text(emoji)
                                        .font(.title2)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(nemesis.opponentNames.joined(separator: " & "))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.foreground)
                                Text("\(nemesis.gamesPlayed) games against")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }

                            Spacer()

                            Text("\(Int(nemesis.winRate * 100))%")
                                .font(.headline)
                                .foregroundColor(nemesis.winRate >= 0.5 ? AppTheme.win : AppTheme.loss)
                        }
                        .cardStyle()
                    }
                }
            }
        }
        .padding()
    }
}
