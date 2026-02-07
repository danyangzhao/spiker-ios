import SwiftUI

// MARK: - Players List View
struct PlayersListView: View {
    @State private var viewModel = PlayersViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.players.isEmpty {
                    LoadingView(message: "Loading players...")
                } else if let error = viewModel.errorMessage, viewModel.players.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadPlayers() }
                    }
                } else if viewModel.players.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No Players Yet",
                        message: "Add your first player to get started!"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.sortedPlayers) { player in
                                NavigationLink(destination: PlayerDetailView(playerId: player.id)) {
                                    PlayerListCard(player: player)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadPlayers()
                    }
                }
            }
            .navigationTitle("Players")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                AddPlayerView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadPlayers()
            }
        }
    }
}

// MARK: - Player List Card
struct PlayerListCard: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            Text(player.emoji)
                .font(.title)
                .frame(width: 48, height: 48)
                .background(AppTheme.card02)
                .cornerRadius(24)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.foreground)

                Text("Rating: \(player.rating)")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()

            Text("\(player.rating)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.accent)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(12)
        .background(AppTheme.card)
        .cornerRadius(12)
    }
}
