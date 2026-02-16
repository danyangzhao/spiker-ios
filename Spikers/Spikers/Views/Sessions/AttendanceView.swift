import SwiftUI

// MARK: - Attendance View
struct AttendanceView: View {
    @Bindable var viewModel: SessionDetailViewModel
    @State private var selectedPlayerIds: Set<String> = []
    @State private var initialized = false
    @State private var saveState: AttendanceSaveState = .idle
    @State private var showSavedToast = false

    private enum AttendanceSaveState: Equatable {
        case idle
        case saving
        case saved
    }

    private var persistedPlayerIds: Set<String> {
        guard let attendances = viewModel.sessionDetail?.attendances else { return [] }
        return Set(attendances.filter { $0.present }.map { $0.playerId })
    }

    private var hasUnsavedChanges: Bool {
        selectedPlayerIds != persistedPlayerIds
    }

    private var buttonTitle: String {
        switch saveState {
        case .idle:
            return "Save Attendance"
        case .saving:
            return "Saving..."
        case .saved:
            return "Attendance Saved"
        }
    }

    private var buttonIcon: String {
        switch saveState {
        case .idle:
            return "square.and.arrow.down"
        case .saving:
            return "hourglass"
        case .saved:
            return "checkmark.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attendance")
                    .font(.headline)
                    .foregroundColor(AppTheme.foreground)

                Spacer()

                let presentCount = viewModel.sessionDetail?.attendances.filter { $0.present }.count ?? 0
                Text("\(presentCount) present")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            // Player checkboxes
            let players = viewModel.allPlayers
            VStack(spacing: 4) {
                ForEach(players) { player in
                    Button {
                        togglePlayer(player.id)
                    } label: {
                        HStack {
                            Image(systemName: selectedPlayerIds.contains(player.id)
                                  ? "checkmark.circle.fill"
                                  : "circle")
                                .foregroundColor(selectedPlayerIds.contains(player.id)
                                                 ? AppTheme.accent
                                                 : AppTheme.secondaryText)

                            Text(player.emoji)
                                .font(.title3)
                            Text(player.name)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.foreground)

                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
            }

            // Save button (only for in-progress sessions)
            if viewModel.sessionDetail?.status == .IN_PROGRESS {
                Button {
                    Task {
                        saveState = .saving
                        let didSave = await viewModel.setAttendance(playerIds: Array(selectedPlayerIds))

                        if didSave {
                            saveState = .saved
                            showSavedToastMessage()
                        } else {
                            saveState = .idle
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: buttonIcon)
                        Text(buttonTitle)
                    }
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(saveState == .saved ? AppTheme.win : AppTheme.accent)
                        .cornerRadius(10)
                }
                .disabled(saveState == .saving || !hasUnsavedChanges)
                .opacity(saveState == .saving || !hasUnsavedChanges ? 0.65 : 1.0)
            }
        }
        .cardStyle()
        .overlay(alignment: .top) {
            if showSavedToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.accent)
                    Text("Attendance saved")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.foreground)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.card03)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.card04, lineWidth: 1)
                )
                .cornerRadius(10)
                .padding(.top, 8)
                .padding(.horizontal, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSavedToast)
        .onAppear {
            if !initialized {
                // Initialize from existing attendance
                if let attendances = viewModel.sessionDetail?.attendances {
                    selectedPlayerIds = Set(attendances.filter { $0.present }.map { $0.playerId })
                }
                initialized = true
            }
        }
    }

    private func togglePlayer(_ id: String) {
        if selectedPlayerIds.contains(id) {
            selectedPlayerIds.remove(id)
        } else {
            selectedPlayerIds.insert(id)
        }
        resetSaveFeedback()
    }

    private func resetSaveFeedback() {
        if saveState == .saved {
            saveState = .idle
        }
        showSavedToast = false
    }

    private func showSavedToastMessage() {
        withAnimation {
            showSavedToast = true
        }

        Task {
            try? await Task.sleep(for: .seconds(1.8))
            await MainActor.run {
                withAnimation {
                    showSavedToast = false
                }
            }
        }
    }
}
