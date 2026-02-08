import SwiftUI

// MARK: - Badge Grid
/// Displays earned and locked badges in a grid layout
struct BadgeGrid: View {
    let badges: [EarnedBadge]
    var allBadges: [Badge] = []
    var badgeProgress: [BadgeProgress] = []

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    /// Badges the player has not yet earned
    private var lockedBadges: [Badge] {
        let earnedCodes = Set(badges.map { $0.code })
        return allBadges.filter { !earnedCodes.contains($0.code) }
    }

    /// Look up progress for a given badge code
    private func progress(for code: String) -> BadgeProgress? {
        badgeProgress.first { $0.code == code }
    }

    var body: some View {
        if badges.isEmpty && allBadges.isEmpty {
            EmptyStateView(
                icon: "medal",
                title: "No Badges Yet",
                message: "Play more games to earn badges!"
            )
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // Earned badges
                if !badges.isEmpty {
                    Text("Earned")
                        .font(.headline)
                        .foregroundColor(AppTheme.foreground)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(badges) { badge in
                            BadgeCard(badge: badge)
                        }
                    }
                }

                // Locked badges
                if !lockedBadges.isEmpty {
                    Text("Locked")
                        .font(.headline)
                        .foregroundColor(AppTheme.secondaryText)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(lockedBadges) { badge in
                            LockedBadgeCard(
                                badge: badge,
                                progress: progress(for: badge.code)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Badge Card (Earned)
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

// MARK: - Locked Badge Card
struct LockedBadgeCard: View {
    let badge: Badge
    let progress: BadgeProgress?

    private var progressFraction: Double {
        guard let progress = progress, progress.target > 0 else { return 0 }
        return Double(progress.current) / Double(progress.target)
    }

    /// Whether this badge has numeric progress to display
    private var showProgress: Bool {
        guard let progress = progress else { return false }
        return progress.target > 1
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("🔒")
                .font(.title2)
                .grayscale(1.0)
                .opacity(0.5)

            Text(badge.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            Text(badge.description)
                .font(.caption2)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .opacity(0.7)

            // Always render progress area to keep card heights consistent.
            // Hidden (but still taking up space) when there's no numeric progress.
            VStack(spacing: 2) {
                ProgressView(value: showProgress ? progressFraction : 0)
                    .tint(AppTheme.accent)

                Text(showProgress ? "\(progress!.current)/\(progress!.target)" : " ")
                    .font(.system(size: 9))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .opacity(showProgress ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(AppTheme.card02)
        .cornerRadius(12)
        .opacity(0.6)
    }
}
