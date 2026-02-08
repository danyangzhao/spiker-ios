import SwiftUI

// MARK: - Badge Detail Item
/// Unified type used to present the badge detail sheet for both earned and locked badges
struct BadgeDetailItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let iconEmoji: String
    let isEarned: Bool
    let earnedByPercent: Int?
    let progress: BadgeProgress?

    /// Create from an earned badge, looking up its earn percentage from allBadges
    init(earned: EarnedBadge, allBadges: [Badge]) {
        self.id = earned.id
        self.name = earned.name
        self.description = earned.description
        self.iconEmoji = earned.iconEmoji
        self.isEarned = true
        self.earnedByPercent = allBadges.first { $0.code == earned.code }?.earnedByPercent
        self.progress = nil
    }

    /// Create from a locked badge
    init(locked: Badge, progress: BadgeProgress?) {
        self.id = locked.id
        self.name = locked.name
        self.description = locked.description
        self.iconEmoji = locked.iconEmoji
        self.isEarned = false
        self.earnedByPercent = locked.earnedByPercent
        self.progress = progress
    }
}

// MARK: - Badge Grid
/// Displays earned and locked badges in a grid layout
struct BadgeGrid: View {
    let badges: [EarnedBadge]
    var allBadges: [Badge] = []
    var badgeProgress: [BadgeProgress] = []

    /// The badge currently selected for the detail sheet
    @State private var selectedBadge: BadgeDetailItem?

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
                                .onTapGesture {
                                    selectedBadge = BadgeDetailItem(
                                        earned: badge,
                                        allBadges: allBadges
                                    )
                                }
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
                            .onTapGesture {
                                selectedBadge = BadgeDetailItem(
                                    locked: badge,
                                    progress: progress(for: badge.code)
                                )
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedBadge) { item in
                BadgeDetailSheet(badge: item)
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

// MARK: - Badge Detail Sheet
/// Modal that shows full badge info when a user taps a badge card
struct BadgeDetailSheet: View {
    let badge: BadgeDetailItem
    @Environment(\.dismiss) private var dismiss

    private var progressFraction: Double {
        guard let progress = badge.progress, progress.target > 0 else { return 0 }
        return Double(progress.current) / Double(progress.target)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Large icon
                    Text(badge.isEarned ? badge.iconEmoji : "🔒")
                        .font(.system(size: 64))
                        .grayscale(badge.isEarned ? 0 : 1.0)
                        .opacity(badge.isEarned ? 1 : 0.5)
                        .padding(.top, 8)

                    // Name and earned status
                    VStack(spacing: 6) {
                        Text(badge.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.foreground)

                        Text(badge.isEarned ? "Earned" : "Locked")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(badge.isEarned ? AppTheme.accent : AppTheme.secondaryText)
                    }

                    // Full description
                    Text(badge.description)
                        .font(.body)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    // Progress bar for locked badges with numeric progress
                    if !badge.isEarned, let progress = badge.progress, progress.target > 1 {
                        VStack(spacing: 6) {
                            ProgressView(value: progressFraction)
                                .tint(AppTheme.accent)
                                .scaleEffect(y: 2)

                            Text("\(progress.current) / \(progress.target)")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(.horizontal, 40)
                    }

                    // Earn percentage stat
                    if let percent = badge.earnedByPercent {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(AppTheme.accent)

                            Text("\(percent)% of players have earned this badge")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.card02)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }

                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.secondaryText)
                            .font(.title3)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(AppTheme.background)
    }
}
