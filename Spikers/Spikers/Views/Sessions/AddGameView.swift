import SwiftUI

// MARK: - Add Game View
struct AddGameView: View {
    @Bindable var viewModel: SessionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Random teams button
                        Button {
                            viewModel.generateRandomTeams()
                        } label: {
                            HStack {
                                Image(systemName: "shuffle")
                                Text("Random Teams")
                            }
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(AppTheme.accent.opacity(0.15))
                            .cornerRadius(10)
                        }

                        // Team A
                        TeamSelector(
                            title: "Team A",
                            players: viewModel.attendingPlayers,
                            selected: $viewModel.selectedTeamA,
                            otherTeam: viewModel.selectedTeamB
                        )

                        // Team B
                        TeamSelector(
                            title: "Team B",
                            players: viewModel.attendingPlayers,
                            selected: $viewModel.selectedTeamB,
                            otherTeam: viewModel.selectedTeamA
                        )

                        // Scores
                        HStack(spacing: 16) {
                            VStack(spacing: 4) {
                                Text("Team A Score")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                TextField("0", text: $viewModel.scoreA)
                                    .keyboardType(.numberPad)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(AppTheme.foreground)
                                    .padding(12)
                                    .background(AppTheme.card02)
                                    .cornerRadius(12)
                            }

                            Text("vs")
                                .font(.title2)
                                .foregroundColor(AppTheme.secondaryText)

                            VStack(spacing: 4) {
                                Text("Team B Score")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                                TextField("0", text: $viewModel.scoreB)
                                    .keyboardType(.numberPad)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(AppTheme.foreground)
                                    .padding(12)
                                    .background(AppTheme.card02)
                                    .cornerRadius(12)
                            }
                        }

                        // Submit
                        Button {
                            Task {
                                await viewModel.createGame()
                                if viewModel.errorMessage == nil {
                                    dismiss()
                                }
                            }
                        } label: {
                            if viewModel.isCreatingGame {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accent.opacity(0.6))
                                    .cornerRadius(12)
                            } else {
                                Text("Add Game")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppTheme.accent)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(viewModel.isCreatingGame)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Team Selector
struct TeamSelector: View {
    let title: String
    let players: [Player]
    @Binding var selected: Set<String>
    let otherTeam: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            // Show available players (not on the other team)
            let available = players.filter { !otherTeam.contains($0.id) }

            if available.isEmpty {
                Text("No players available")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(available) { player in
                        Button {
                            if selected.contains(player.id) {
                                selected.remove(player.id)
                            } else {
                                selected.insert(player.id)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(player.emoji)
                                Text(player.name)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selected.contains(player.id)
                                        ? AppTheme.accent
                                        : AppTheme.card02)
                            .foregroundColor(selected.contains(player.id)
                                             ? .white
                                             : AppTheme.foreground)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Flow Layout (wrapping horizontal layout)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
