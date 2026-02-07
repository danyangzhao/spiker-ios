import SwiftUI

// MARK: - Empty State View
/// Shown when a list has no items
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.secondaryText)

            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Status Badge
/// A small colored pill showing session status
struct StatusBadge: View {
    let status: SessionStatus

    var label: String {
        switch status {
        case .UPCOMING: return "Upcoming"
        case .IN_PROGRESS: return "Live"
        case .COMPLETED: return "Completed"
        }
    }

    var color: Color {
        switch status {
        case .UPCOMING: return AppTheme.upcoming
        case .IN_PROGRESS: return AppTheme.live
        case .COMPLETED: return AppTheme.completed
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Game Card
/// Shows a single game result with teams and scores
struct GameCard: View {
    let game: Game
    let gameNumber: Int

    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text("Game \(gameNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.secondaryText)
                Spacer()
            }

            // Scores
            HStack(spacing: 0) {
                // Team A
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(game.teamAPlayers) { player in
                            PlayerChip(
                                emoji: player.emoji,
                                name: player.name,
                                isWinner: game.scoreA > game.scoreB
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Score
                HStack(spacing: 4) {
                    Text("\(game.scoreA)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(game.scoreA > game.scoreB ? AppTheme.win : AppTheme.foreground)

                    Text("-")
                        .font(.title3)
                        .foregroundColor(AppTheme.secondaryText)

                    Text("\(game.scoreB)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(game.scoreB > game.scoreA ? AppTheme.win : AppTheme.foreground)
                }
                .padding(.horizontal, 8)

                // Team B
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(game.teamBPlayers) { player in
                            PlayerChip(
                                emoji: player.emoji,
                                name: player.name,
                                isWinner: game.scoreB > game.scoreA
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(12)
        .background(AppTheme.card01)
        .cornerRadius(12)
    }
}
