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
