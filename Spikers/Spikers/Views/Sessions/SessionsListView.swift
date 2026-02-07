import SwiftUI

// MARK: - Sessions List View
struct SessionsListView: View {
    @State private var viewModel = SessionsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    LoadingView(message: "Loading sessions...")
                } else if let error = viewModel.errorMessage, viewModel.sessions.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadSessions() }
                    }
                } else if viewModel.sessions.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "No Sessions Yet",
                        message: "Create your first session to get started!"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Live Sessions
                            if !viewModel.liveSessions.isEmpty {
                                SessionGroup(title: "Live", sessions: viewModel.liveSessions)
                            }

                            // Upcoming Sessions
                            if !viewModel.upcomingSessions.isEmpty {
                                SessionGroup(title: "Upcoming", sessions: viewModel.upcomingSessions)
                            }

                            // Completed Sessions
                            if !viewModel.completedSessions.isEmpty {
                                SessionGroup(title: "Completed", sessions: viewModel.completedSessions)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadSessions()
                    }
                }
            }
            .navigationTitle("Sessions")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateSessionView(viewModel: viewModel)
            }
            .task {
                await viewModel.loadSessions()
            }
        }
    }
}

// MARK: - Session Group
struct SessionGroup: View {
    let title: String
    let sessions: [Session]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            VStack(spacing: 8) {
                ForEach(sessions) { session in
                    NavigationLink(destination: SessionDetailView(sessionId: session.id)) {
                        SessionRowCard(session: session)
                    }
                }
            }
        }
    }
}

// MARK: - Session Row Card
struct SessionRowCard: View {
    let session: Session

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(formatDate(session.date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.foreground)
                    StatusBadge(status: session.status)
                }

                if let location = session.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.secondaryText)
                }
            }

            Spacer()

            if let count = session._count {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(count.games) games")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    Text("\(count.attendances) players")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(12)
        .background(AppTheme.card)
        .cornerRadius(12)
    }
}
