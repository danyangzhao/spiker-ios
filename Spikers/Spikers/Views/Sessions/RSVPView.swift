import SwiftUI

// MARK: - RSVP View
struct RSVPView: View {
    @Bindable var viewModel: SessionDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RSVP")
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            // Summary
            if let summary = viewModel.rsvpResponse?.summary {
                HStack(spacing: 16) {
                    RSVPCountBadge(label: "Going", count: summary.going, color: .green)
                    RSVPCountBadge(label: "Maybe", count: summary.maybe, color: .yellow)
                    RSVPCountBadge(label: "Out", count: summary.out, color: .red)
                }
            }

            // Player list with RSVP buttons
            if let playerRsvps = viewModel.rsvpResponse?.playerRsvps {
                VStack(spacing: 8) {
                    ForEach(playerRsvps) { pr in
                        HStack {
                            Text(pr.player.emoji)
                                .font(.title3)
                            Text(pr.player.name)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.foreground)

                            Spacer()

                            // RSVP buttons
                            HStack(spacing: 4) {
                                RSVPButton(label: "In", isSelected: pr.status == .GOING, color: .green) {
                                    Task { await viewModel.setRSVP(playerId: pr.player.id, status: .GOING) }
                                }
                                RSVPButton(label: "?", isSelected: pr.status == .MAYBE, color: .yellow) {
                                    Task { await viewModel.setRSVP(playerId: pr.player.id, status: .MAYBE) }
                                }
                                RSVPButton(label: "Out", isSelected: pr.status == .OUT, color: .red) {
                                    Task { await viewModel.setRSVP(playerId: pr.player.id, status: .OUT) }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - RSVP Count Badge
struct RSVPCountBadge: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - RSVP Button
struct RSVPButton: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.15))
                .cornerRadius(8)
        }
    }
}
