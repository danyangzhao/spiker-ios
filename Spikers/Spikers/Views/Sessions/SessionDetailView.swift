import SwiftUI

// MARK: - Session Detail View
struct SessionDetailView: View {
    let sessionId: String
    @State private var viewModel: SessionDetailViewModel
    @State private var selectedTab = 0

    init(sessionId: String) {
        self.sessionId = sessionId
        self._viewModel = State(initialValue: SessionDetailViewModel(sessionId: sessionId))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.sessionDetail == nil {
                LoadingView(message: "Loading session...")
            } else if let error = viewModel.errorMessage, viewModel.sessionDetail == nil {
                ErrorView(message: error) {
                    Task { await viewModel.loadData() }
                }
            } else if let detail = viewModel.sessionDetail {
                VStack(spacing: 0) {
                    // Session header
                    SessionHeader(detail: detail, viewModel: viewModel)

                    // Tab picker
                    Picker("Section", selection: $selectedTab) {
                        Text("Overview").tag(0)
                        Text("Games").tag(1)
                        Text("Summary").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // Tab content
                    ScrollView {
                        switch selectedTab {
                        case 0:
                            OverviewTab(viewModel: viewModel)
                        case 1:
                            GamesTab(viewModel: viewModel)
                        case 2:
                            SummaryTab(viewModel: viewModel)
                        default:
                            EmptyView()
                        }
                    }
                    .refreshable {
                        await viewModel.loadData()
                    }
                }
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await viewModel.loadData()
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil && viewModel.sessionDetail != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Session Header
struct SessionHeader: View {
    let detail: SessionDetail
    @Bindable var viewModel: SessionDetailViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(formatDate(detail.date))
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        Button {
                            viewModel.prepareEditSession()
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }

                    if let location = detail.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption)
                            Text(location)
                                .font(.subheadline)
                        }
                        .foregroundColor(AppTheme.secondaryText)
                    }
                }
                Spacer()
                StatusBadge(status: detail.status)
            }

            // Status control buttons
            if detail.status == .UPCOMING {
                Button {
                    Task { await viewModel.startSession() }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Session")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(AppTheme.live)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isUpdatingStatus)
            } else if detail.status == .IN_PROGRESS {
                Button {
                    Task { await viewModel.completeSession() }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Session")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(AppTheme.accent)
                    .cornerRadius(10)
                }
                .disabled(viewModel.isUpdatingStatus)
            }
        }
        .padding()
        .background(AppTheme.card)
        .sheet(isPresented: $viewModel.showEditSheet) {
            EditSessionView(viewModel: viewModel)
        }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    @Bindable var viewModel: SessionDetailViewModel

    var body: some View {
        VStack(spacing: 16) {
            // RSVP section (for upcoming sessions)
            if viewModel.sessionDetail?.status == .UPCOMING {
                RSVPView(viewModel: viewModel)
            }

            // Attendance section (for in-progress/completed)
            if viewModel.sessionDetail?.status == .IN_PROGRESS ||
               viewModel.sessionDetail?.status == .COMPLETED {
                AttendanceView(viewModel: viewModel)
            }
        }
        .padding()
    }
}

// MARK: - Games Tab
struct GamesTab: View {
    @Bindable var viewModel: SessionDetailViewModel

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.sessionDetail?.status == .IN_PROGRESS {
                tournamentControls
            }

            if viewModel.sessionDetail?.status == .IN_PROGRESS {
                // Add Game button
                Button {
                    viewModel.showAddGame = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Game")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(AppTheme.accent)
                    .cornerRadius(12)
                }
            }

            let games = viewModel.sessionDetail?.games ?? []

            if games.isEmpty {
                EmptyStateView(
                    icon: "sportscourt",
                    title: "No Games Yet",
                    message: "Start the session and add games to track scores"
                )
            } else {
                ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                    GameCard(game: game, gameNumber: index + 1)
                        .contextMenu {
                            if viewModel.sessionDetail?.status == .IN_PROGRESS {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteGame(id: game.id) }
                                } label: {
                                    Label("Delete Game", systemImage: "trash")
                                }
                            }
                        }
                }
            }
        }
        .padding()
        .sheet(isPresented: $viewModel.showAddGame) {
            AddGameView(viewModel: viewModel)
        }
        .confirmationDialog("Tournament Setup", isPresented: $viewModel.showTournamentSetup) {
            Button("Random Teams") {
                Task { await viewModel.setupTournament(mode: .RANDOM) }
            }
            Button("Fair Teams (ELO)") {
                Task { await viewModel.setupTournament(mode: .FAIR) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Use the current attendees to create a tournament.")
        }
        .sheet(isPresented: $viewModel.showTournamentBracket) {
            if let tournament = viewModel.tournament {
                TournamentBracketView(
                    tournament: tournament,
                    attendingPlayers: viewModel.attendingPlayers,
                    scoreA: $viewModel.tournamentScoreA,
                    scoreB: $viewModel.tournamentScoreB,
                    isSubmittingGame: viewModel.isSubmittingTournamentGame,
                    activeMatch: viewModel.activeTournamentMatch,
                    onSubmitGame: { matchId in
                        Task { await viewModel.recordTournamentGame(matchId: matchId) }
                    },
                    onEndTournament: {
                        Task { await viewModel.endTournament() }
                    },
                    isEndingTournament: viewModel.isEndingTournament
                )
            }
        }
    }

    @ViewBuilder
    private var tournamentControls: some View {
        VStack(spacing: 8) {
            if viewModel.canSetupTournament {
                Button {
                    viewModel.showTournamentSetup = true
                } label: {
                    HStack {
                        Image(systemName: "trophy")
                        Text("Tournament Mode")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.tournamentBlue)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(AppTheme.tournamentBlue.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.tournamentBlue.opacity(0.65), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
            } else if let tournament = viewModel.tournament {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tournament Active")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.tournamentBlue)
                            Text("Stage: \(readableStage(tournament.stage))")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        Spacer()
                        Button("View Bracket") {
                            viewModel.showTournamentBracket = true
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.tournamentBlue)
                    }

                    if tournament.status == .ACTIVE {
                        Button(role: .destructive) {
                            Task { await viewModel.endTournament() }
                        } label: {
                            Text(viewModel.isEndingTournament ? "Ending Tournament..." : "End Tournament")
                                .font(.caption)
                        }
                        .disabled(viewModel.isEndingTournament)
                    }
                }
                .padding(12)
                .background(AppTheme.card02)
                .cornerRadius(12)
            }
        }
    }

    private func readableStage(_ stage: TournamentStage) -> String {
        switch stage {
        case .ROUND_ROBIN: return "Round Robin"
        case .BRACKET: return "Bracket"
        case .FINALS: return "Finals"
        case .COMPLETED: return "Completed"
        case .ENDED: return "Ended"
        }
    }
}

// MARK: - Summary Tab
struct SummaryTab: View {
    @Bindable var viewModel: SessionDetailViewModel

    private var hasAnyAward: Bool {
        guard let summary = viewModel.summary else { return false }
        return summary.playerOfTheDay != nil
            || summary.ironman != nil
            || summary.socialButterfly != nil
            || summary.clutchPlayer != nil
            || summary.theWall != nil
            || summary.hotStreak != nil
    }

    var body: some View {
        VStack(spacing: 16) {
            if let summary = viewModel.summary {
                // Total games
                if let total = summary.totalGames {
                    StatCard(label: "Total Games", value: "\(total)")
                }

                // Highlights
                if let highlights = summary.highlights, !highlights.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Highlights")
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        ForEach(highlights, id: \.self) { highlight in
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.accent)
                                Text(highlight)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.foreground)
                            }
                        }
                    }
                    .cardStyle()
                }

                // Awards
                VStack(alignment: .leading, spacing: 12) {
                    Text("Awards")
                        .font(.headline)
                        .foregroundColor(AppTheme.foreground)

                    if let potd = summary.playerOfTheDay {
                        AwardRow(
                            emoji: "🏆",
                            title: "Player of the Day",
                            playerEmoji: potd.emoji,
                            playerName: potd.name,
                            detail: "\(potd.wins) wins"
                        )
                    }

                    if let ironman = summary.ironman {
                        AwardRow(
                            emoji: "💪",
                            title: "Ironman",
                            playerEmoji: ironman.emoji,
                            playerName: ironman.name,
                            detail: "\(ironman.gamesPlayed) games"
                        )
                    }

                    if let butterfly = summary.socialButterfly {
                        AwardRow(
                            emoji: "🦋",
                            title: "Social Butterfly",
                            playerEmoji: butterfly.emoji,
                            playerName: butterfly.name,
                            detail: "\(butterfly.uniqueTeammates) teammates"
                        )
                    }

                    if let clutch = summary.clutchPlayer {
                        AwardRow(
                            emoji: "🎯",
                            title: "Clutch Player",
                            playerEmoji: clutch.emoji,
                            playerName: clutch.name,
                            detail: "\(clutch.closeGameWins) close wins"
                        )
                    }

                    if let wall = summary.theWall {
                        AwardRow(
                            emoji: "🧱",
                            title: "The Wall",
                            playerEmoji: wall.emoji,
                            playerName: wall.name,
                            detail: String(format: "%.1f avg pts against", wall.avgPointsAgainst)
                        )
                    }

                    if let streak = summary.hotStreak {
                        AwardRow(
                            emoji: "🔥",
                            title: "Hot Streak",
                            playerEmoji: streak.emoji,
                            playerName: streak.name,
                            detail: "\(streak.streak) wins in a row"
                        )
                    }

                    if !hasAnyAward {
                        Text("No awards yet - play more games!")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                .cardStyle()

                // Game Spotlights
                if summary.closestGame != nil || summary.biggestBlowout != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Game Spotlights")
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        if let closest = summary.closestGame {
                            GameSpotlightRow(
                                icon: "flame",
                                title: "Closest Game",
                                gameNumber: closest.gameNumber,
                                scoreA: closest.scoreA,
                                scoreB: closest.scoreB
                            )
                        }

                        if let blowout = summary.biggestBlowout {
                            GameSpotlightRow(
                                icon: "bolt.fill",
                                title: "Biggest Blowout",
                                gameNumber: blowout.gameNumber,
                                scoreA: blowout.scoreA,
                                scoreB: blowout.scoreB
                            )
                        }
                    }
                    .cardStyle()
                }

                // Player Stats Table
                if let stats = summary.playerStats, !stats.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Player Stats")
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        ForEach(stats) { stat in
                            HStack {
                                Text(stat.emoji)
                                Text(stat.name)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.foreground)
                                Spacer()
                                Text("\(stat.wins)W-\(stat.losses)L")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                Text(stat.pointDiff >= 0 ? "+\(stat.pointDiff)" : "\(stat.pointDiff)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(stat.pointDiff >= 0 ? AppTheme.win : AppTheme.loss)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .cardStyle()
                }
            } else {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Summary Available",
                    message: "Complete the session to see awards and stats"
                )
            }
        }
        .padding()
    }
}

// MARK: - Game Spotlight Row
struct GameSpotlightRow: View {
    let icon: String
    let title: String
    let gameNumber: Int
    let scoreA: Int
    let scoreB: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
                Text("Game \(gameNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.foreground)
            }

            Spacer()

            Text("\(scoreA) - \(scoreB)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.accent)
        }
        .padding(8)
        .background(AppTheme.card02)
        .cornerRadius(10)
    }
}

// MARK: - Award Row
struct AwardRow: View {
    let emoji: String
    let title: String
    let playerEmoji: String
    let playerName: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)

                HStack(spacing: 4) {
                    Text(playerEmoji)
                    Text(playerName)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.foreground)
                }
            }

            Spacer()

            Text(detail)
                .font(.caption)
                .foregroundColor(AppTheme.accent)
        }
        .padding(8)
        .background(AppTheme.card02)
        .cornerRadius(10)
    }
}
