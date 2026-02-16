import SwiftUI

struct TournamentBracketView: View {
    let tournament: TournamentState
    @Binding var scoreA: String
    @Binding var scoreB: String
    let isSubmittingGame: Bool
    let activeMatch: TournamentMatch?
    let onSubmitGame: (String) -> Void
    let onEndTournament: () -> Void
    let isEndingTournament: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerCard

                        if let activeMatch, tournament.status == .ACTIVE {
                            activeSeriesCard(activeMatch)
                        }

                        ForEach(groupedStages, id: \.0) { stage, matches in
                            stageCard(stage: stage, matches: matches)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Tournament Bracket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(AppTheme.tournamentBlue)
                }
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(statusText)
                .font(.headline)
                .foregroundColor(AppTheme.tournamentBlue)
            Text("Team mode: \(tournament.teamMode.rawValue.capitalized)")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)

            if tournament.status == .ACTIVE {
                Button(role: .destructive) {
                    onEndTournament()
                } label: {
                    Text(isEndingTournament ? "Ending..." : "End Tournament")
                        .font(.caption)
                }
                .disabled(isEndingTournament)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.card)
        .cornerRadius(12)
    }

    private func activeSeriesCard(_ match: TournamentMatch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Match (Best of 3)")
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            matchLabel(match)

            HStack(spacing: 12) {
                TextField("Team A", text: $scoreA)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(AppTheme.card02)
                    .cornerRadius(10)

                TextField("Team B", text: $scoreB)
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(AppTheme.card02)
                    .cornerRadius(10)
            }

            Button {
                onSubmitGame(match.id)
            } label: {
                Text(isSubmittingGame ? "Submitting..." : "Record Game")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(AppTheme.tournamentBlue)
                    .cornerRadius(10)
            }
            .disabled(isSubmittingGame)
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(12)
    }

    private func stageCard(stage: TournamentMatchStage, matches: [TournamentMatch]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(stageTitle(stage))
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            ForEach(matches) { match in
                VStack(alignment: .leading, spacing: 6) {
                    matchLabel(match)
                    Text("Series: \(match.winsA)-\(match.winsB)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                    if match.isComplete {
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(AppTheme.win)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.card02)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(AppTheme.card)
        .cornerRadius(12)
    }

    private func matchLabel(_ match: TournamentMatch) -> some View {
        let left = teamName(match.teamA, playerIds: match.teamAPlayerIds)
        let right = teamName(match.teamB, playerIds: match.teamBPlayerIds)
        return Text("\(left) vs \(right)")
            .font(.subheadline)
            .foregroundColor(AppTheme.foreground)
    }

    private func teamName(_ team: TournamentTeam?, playerIds: [String]) -> String {
        if let team {
            return team.name
        }
        let players = tournament.teams
            .flatMap { [$0.playerA, $0.playerB].compactMap { $0 } }
            .filter { playerIds.contains($0.id) }
        if players.isEmpty {
            return "TBD"
        }
        return players.map { "\($0.emoji)\($0.name)" }.joined(separator: " + ")
    }

    private var groupedStages: [(TournamentMatchStage, [TournamentMatch])] {
        let grouped = Dictionary(grouping: tournament.matches) { $0.stage }
        let order: [TournamentMatchStage] = [.ROUND_ROBIN, .BRACKET, .WINNERS_FINAL, .LOSERS_FINAL]
        return order.compactMap { stage in
            guard let matches = grouped[stage], !matches.isEmpty else { return nil }
            return (stage, matches.sorted { lhs, rhs in
                if lhs.round != rhs.round { return lhs.round < rhs.round }
                return lhs.slot < rhs.slot
            })
        }
    }

    private var statusText: String {
        switch tournament.status {
        case .ACTIVE: return "Tournament in progress"
        case .COMPLETED: return "Tournament complete"
        case .ENDED: return "Tournament ended early"
        }
    }

    private func stageTitle(_ stage: TournamentMatchStage) -> String {
        switch stage {
        case .ROUND_ROBIN: return "Round Robin"
        case .BRACKET: return "Bracket"
        case .WINNERS_FINAL: return "Winners Final"
        case .LOSERS_FINAL: return "Losers Final (3rd Place)"
        }
    }
}
