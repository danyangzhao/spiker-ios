import SwiftUI

struct SeasonAnnouncementView: View {
    let upcomingSeason: Season
    let currentActiveSeason: Season?

    @State private var carryOverPlayers: [Player] = []
    @State private var resolvedCurrentSeason: Season?
    @State private var isLoadingPlayers = true

    private let playerService = PlayerService()
    private let seasonService = SeasonService()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            List {
                Section("Announcement") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(upcomingSeason.name)
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        Text(relativeStartText)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accent)

                        Text("Starts \(formatDate(upcomingSeason.scheduledStartAt ?? upcomingSeason.startedAt))")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .listRowBackground(AppTheme.card)
                }

                Section("Carries Over") {
                    if isLoadingPlayers {
                        ProgressView("Loading roster...")
                            .foregroundColor(AppTheme.secondaryText)
                            .listRowBackground(AppTheme.card)
                    } else if carryOverPlayers.isEmpty {
                        Text("No carry-over players were selected.")
                            .foregroundColor(AppTheme.secondaryText)
                            .listRowBackground(AppTheme.card)
                    } else {
                        ForEach(carryOverPlayers) { player in
                            HStack(spacing: 10) {
                                Text(player.emoji)
                                Text(player.name)
                                    .foregroundColor(AppTheme.foreground)
                                Spacer()
                            }
                            .listRowBackground(AppTheme.card)
                        }
                    }
                }

                Section {
                    if let resolvedCurrentSeason {
                        NavigationLink(destination: SeasonDetailView(season: resolvedCurrentSeason)) {
                            Text("View current season")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowBackground(AppTheme.accent.opacity(0.2))
                    } else {
                        Text("Current season unavailable")
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .listRowBackground(AppTheme.card)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Season Announcement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            resolvedCurrentSeason = currentActiveSeason?.id == upcomingSeason.id ? nil : currentActiveSeason
            await loadCarryOverPlayers()
            await resolveCurrentSeason()
        }
    }

    private var relativeStartText: String {
        guard let startDate = parseISODate(upcomingSeason.scheduledStartAt ?? upcomingSeason.startedAt) else {
            return "Start date announced"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Starts \(formatter.localizedString(for: startDate, relativeTo: Date()))"
    }

    private func parseISODate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    private func loadCarryOverPlayers() async {
        isLoadingPlayers = true
        defer { isLoadingPlayers = false }

        do {
            let allPlayers = try await playerService.fetchPlayers(activeOnly: false)
            let carryOverIdSet = Set(upcomingSeason.carryOverPlayerIds)
            carryOverPlayers = allPlayers
                .filter { carryOverIdSet.contains($0.id) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            carryOverPlayers = []
        }
    }

    private func resolveCurrentSeason() async {
        do {
            let seasons = try await seasonService.fetchSeasons()
            if let activeSeason = seasons.first(where: { $0.isActive && $0.id != upcomingSeason.id }) {
                resolvedCurrentSeason = activeSeason
            }
        } catch {
            // Keep the best known current season if season fetch fails.
        }
    }
}
