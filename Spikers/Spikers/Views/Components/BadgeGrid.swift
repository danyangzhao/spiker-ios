import SwiftUI

// MARK: - Badge Grid
/// Displays earned badges in a grid layout
struct BadgeGrid: View {
    let badges: [EarnedBadge]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        if badges.isEmpty {
            EmptyStateView(
                icon: "medal",
                title: "No Badges Yet",
                message: "Play more games to earn badges!"
            )
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(badges) { badge in
                    BadgeCard(badge: badge)
                }
            }
        }
    }
}

// MARK: - Badge Card
struct BadgeCard: View {
    let badge: EarnedBadge

    var body: some View {
        VStack(spacing: 8) {
            Text(badge.iconEmoji)
                .font(.largeTitle)

            Text(badge.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.foreground)
                .multilineTextAlignment(.center)

            Text(badge.description)
                .font(.caption2)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(AppTheme.card02)
        .cornerRadius(12)
    }
}
