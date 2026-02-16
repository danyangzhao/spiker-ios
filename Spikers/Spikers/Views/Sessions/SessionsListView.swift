import SwiftUI

// MARK: - Sessions List View
struct SessionsListView: View {
    @State private var viewModel = SessionsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading && !viewModel.hasVisibleSessions {
                    LoadingView(message: "Loading sessions...")
                } else if let error = viewModel.errorMessage, !viewModel.hasVisibleSessions {
                    ErrorView(message: error) {
                        Task { await viewModel.loadSessions() }
                    }
                } else if !viewModel.hasVisibleSessions {
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
                                SessionGroup(title: "Live", sessions: viewModel.liveSessions, viewModel: viewModel)
                            }

                            // Upcoming Sessions
                            if !viewModel.upcomingSessions.isEmpty {
                                SessionGroup(title: "Upcoming", sessions: viewModel.upcomingSessions, viewModel: viewModel)
                            }

                            // Completed Sessions
                            if !viewModel.completedSessions.isEmpty {
                                SessionGroup(title: "Completed", sessions: viewModel.completedSessions, viewModel: viewModel)
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
            .alert("Delete Session?", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    viewModel.sessionToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    viewModel.confirmDeleteSession()
                }
            } message: {
                Text("This session has games that have been played. Are you sure you want to delete it?")
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
    var viewModel: SessionsViewModel

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
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.requestDeleteSession(session)
                        } label: {
                            Label("Delete Session", systemImage: "trash")
                        }
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
