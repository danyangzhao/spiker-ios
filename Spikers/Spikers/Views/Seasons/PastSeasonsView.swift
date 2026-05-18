import SwiftUI

// MARK: - Seasons Browser
struct PastSeasonsView: View {
    @State private var seasons: [Season] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let seasonService = SeasonService()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if isLoading {
                LoadingView(message: "Loading seasons...")
            } else if let errorMessage {
                ErrorView(message: errorMessage) {
                    Task { await loadSeasons() }
                }
            } else if pastSeasons.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    title: "No Past Seasons Yet",
                    message: "You're currently in your first season. Past seasons will appear here after you start a new one."
                )
            } else {
                List {
                    ForEach(pastSeasons) { season in
                        NavigationLink(destination: SeasonDetailView(season: season)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(season.name)
                                        .foregroundColor(AppTheme.foreground)
                                    Text("Season \(season.number)")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                Spacer()
                                if season.isActive {
                                    Text("Current")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(AppTheme.accent.opacity(0.2))
                                        .foregroundColor(AppTheme.accent)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .listRowBackground(AppTheme.card)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Past Seasons")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadSeasons()
        }
    }

    private func loadSeasons() async {
        isLoading = true
        errorMessage = nil
        do {
            seasons = try await seasonService.fetchSeasons()
        } catch let apiError as APIError {
            // Graceful handling:
            // - First season often has no historical data.
            // - Older backend deployments may not have /api/seasons yet (404).
            if case let .httpError(statusCode, _) = apiError, statusCode == 404 {
                seasons = []
                errorMessage = nil
            } else {
                errorMessage = apiError.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var pastSeasons: [Season] {
        seasons.filter { !$0.isActive }
    }
}

// MARK: - Season Detail Screen
struct SeasonDetailView: View {
    let season: Season

    @State private var detail: SeasonDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let seasonService = SeasonService()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if isLoading {
                LoadingView(message: "Loading season details...")
            } else if let errorMessage {
                ErrorView(message: errorMessage) {
                    Task { await loadDetail() }
                }
            } else if let detail {
                List {
                    Section("Standings") {
                        ForEach(detail.standings) { standing in
                            HStack {
                                Text("#\(standing.rank)")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                    .frame(width: 28, alignment: .leading)
                                Text(standing.player.emoji)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(standing.player.name)
                                        .foregroundColor(AppTheme.foreground)
                                    Text("\(standing.wins)-\(standing.losses) • \(standing.gamesPlayed) games")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                Spacer()
                                Text("\(standing.finalRating)")
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.accent)
                            }
                            .listRowBackground(AppTheme.card)
                        }
                    }

                    Section("Badges Earned") {
                        if detail.badges.isEmpty {
                            Text("No badges earned this season yet.")
                                .foregroundColor(AppTheme.secondaryText)
                                .listRowBackground(AppTheme.card)
                        } else {
                            ForEach(detail.badges) { earned in
                                HStack {
                                    Text(earned.badge.iconEmoji)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(earned.badge.name)
                                            .foregroundColor(AppTheme.foreground)
                                        Text(earned.player.name)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                }
                                .listRowBackground(AppTheme.card)
                            }
                        }
                    }

                    Section("Sessions") {
                        if detail.sessions.isEmpty {
                            Text("No sessions recorded in this season.")
                                .foregroundColor(AppTheme.secondaryText)
                                .listRowBackground(AppTheme.card)
                        } else {
                            ForEach(detail.sessions) { session in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.date)
                                        .foregroundColor(AppTheme.foreground)
                                    Text("\(session.count.games) games • \(session.count.attendances) attendees")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                .listRowBackground(AppTheme.card)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(season.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            detail = try await seasonService.fetchSeasonDetail(id: season.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
