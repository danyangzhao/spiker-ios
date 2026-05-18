import SwiftUI

// MARK: - Start New Season Flow
struct StartNewSeasonView: View {
    private enum Step: Int {
        case confirm
        case roster
        case naming
    }

    @Environment(\.dismiss) private var dismiss

    @State private var step: Step = .confirm
    @State private var players: [Player] = []
    @State private var selectedPlayerIds = Set<String>()
    @State private var seasonName = ""
    @State private var scheduleForLater = false
    @State private var scheduledStartDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isLoadingPlayers = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    @State private var createdSeason: Season?

    private let playerService = PlayerService()
    private let seasonService = SeasonService()

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            SwiftUI.Group {
                if isLoadingPlayers {
                    LoadingView(message: "Loading players...")
                } else {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 16) {
                                header

                                switch step {
                                case .confirm:
                                    confirmStep
                                case .roster:
                                    rosterStep
                                case .naming:
                                    namingStep
                                }

                                if let errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.bottom, 12)
                        }
                        footer
                            .padding(.horizontal)
                            .padding(.bottom)
                    }
                }
            }
        }
        .navigationTitle("Start New Season")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await loadPlayers()
        }
        .alert(successTitle, isPresented: $showSuccessAlert) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text(successMessage)
        }
    }

    private var header: some View {
        HStack {
            Text("Step \(step.rawValue + 1) of 3")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            Spacer()
        }
    }

    private var confirmStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Start a New Season")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.foreground)

            Text("This will end the current season and reset ELO/stats for players you carry over.")
                .foregroundColor(AppTheme.secondaryText)

            Text("Previous season history stays available in Past Seasons.")
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var rosterStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose who carries over")
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(players) { player in
                        Button {
                            togglePlayer(player.id)
                        } label: {
                            HStack {
                                Text(player.emoji)
                                Text(player.name)
                                    .foregroundColor(AppTheme.foreground)
                                Spacer()
                                Image(systemName: selectedPlayerIds.contains(player.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPlayerIds.contains(player.id) ? AppTheme.accent : AppTheme.secondaryText)
                            }
                            .padding(12)
                            .background(AppTheme.card)
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }

    private var namingStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name the new season (optional)")
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            TextField("Season 2", text: $seasonName)
                .padding()
                .background(AppTheme.card)
                .foregroundColor(AppTheme.foreground)
                .cornerRadius(10)

            Text("\(selectedPlayerIds.count) player(s) will carry over and reset to base ELO.")
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)

            Toggle("Schedule for later", isOn: $scheduleForLater)
                .foregroundColor(AppTheme.foreground)

            if scheduleForLater {
                DatePicker(
                    "Season starts",
                    selection: $scheduledStartDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .foregroundColor(AppTheme.foreground)
                .padding()
                .background(AppTheme.card)
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step != .confirm {
                Button("Back") {
                    errorMessage = nil
                    if let previous = Step(rawValue: step.rawValue - 1) {
                        step = previous
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.card03)
                .foregroundColor(AppTheme.foreground)
                .cornerRadius(10)
            }

            Button {
                Task { await advance() }
            } label: {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text(step == .naming ? "Start Season" : "Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(step == .roster && selectedPlayerIds.isEmpty ? AppTheme.card03 : AppTheme.accent)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isSubmitting || (step == .roster && selectedPlayerIds.isEmpty))
        }
    }

    private func togglePlayer(_ id: String) {
        if selectedPlayerIds.contains(id) {
            selectedPlayerIds.remove(id)
        } else {
            selectedPlayerIds.insert(id)
        }
    }

    private func loadPlayers() async {
        isLoadingPlayers = true
        errorMessage = nil
        do {
            let fetched = try await playerService.fetchPlayers(activeOnly: false)
            players = fetched
            selectedPlayerIds = Set(fetched.filter { $0.isActive }.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingPlayers = false
    }

    private func advance() async {
        errorMessage = nil

        if step == .confirm {
            step = .roster
            return
        }

        if step == .roster {
            if selectedPlayerIds.isEmpty {
                errorMessage = "Please select at least one player to carry over."
                return
            }
            step = .naming
            return
        }

        isSubmitting = true
        do {
            let scheduledStartAt = scheduleForLater ? scheduledStartDate : nil
            createdSeason = try await seasonService.startSeason(
                name: seasonName,
                carryOverPlayerIds: Array(selectedPlayerIds),
                scheduledStartAt: scheduledStartAt
            )
            showSuccessAlert = true
        } catch let apiError as APIError {
            if case let .httpError(statusCode, _) = apiError, statusCode == 404 {
                errorMessage = "Starting seasons is not available on the server yet. Please deploy/update the backend first."
            } else {
                errorMessage = apiError.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }

    private var successTitle: String {
        if createdSeason?.isActive == false {
            return "Season change announced"
        }
        return "New season started"
    }

    private var successMessage: String {
        if createdSeason?.isActive == false {
            return "Your next season is scheduled and announced. The home banner will show the upcoming change."
        }
        return "Ratings and season stats are now reset for selected players."
    }
}
