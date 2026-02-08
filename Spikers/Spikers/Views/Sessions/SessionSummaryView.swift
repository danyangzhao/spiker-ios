import SwiftUI

// MARK: - Session Summary View (standalone, for navigation)
/// This is used when navigating to a session summary from elsewhere.
/// The inline summary in session detail uses the SummaryTab directly.
struct SessionSummaryView: View {
    let sessionId: String
    @State private var summary: SessionSummary?
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let sessionService = SessionService()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if isLoading {
                LoadingView(message: "Loading summary...")
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadSummary() }
                }
            } else if let summary {
                ScrollView {
                    VStack(spacing: 16) {
                        // Highlights
                        if let highlights = summary.highlights, !highlights.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
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
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadSummary()
        }
    }

    private func loadSummary() async {
        isLoading = true
        do {
            summary = try await sessionService.fetchSummary(sessionId: sessionId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
