import SwiftUI

// MARK: - Player Chip
/// A small pill showing a player's emoji and name, used in game cards and team lists
struct PlayerChip: View {
    let emoji: String
    let name: String
    var isWinner: Bool = false
    var compact: Bool = false

    private var displayName: String {
        compact ? String(name.prefix(3)) : name
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.caption)
            Text(displayName)
                .font(compact ? .caption2 : .caption)
                .fontWeight(isWinner ? .bold : .regular)
                .foregroundColor(AppTheme.foreground)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, 4)
        .background(AppTheme.card02)
        .cornerRadius(12)
    }
}

// MARK: - Player Row
/// A larger row showing player emoji, name, and rating - for lists
struct PlayerRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            Text(player.emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(AppTheme.card02)
                .cornerRadius(20)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.foreground)
            }

            Spacer()

            Text("\(player.rating)")
                .font(.headline)
                .foregroundColor(AppTheme.accent)
        }
        .padding(.vertical, 4)
    }
}
