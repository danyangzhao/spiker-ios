import SwiftUI

// MARK: - Attendance View
struct AttendanceView: View {
    @Bindable var viewModel: SessionDetailViewModel
    @State private var selectedPlayerIds: Set<String> = []
    @State private var initialized = false

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
                        await viewModel.setAttendance(playerIds: Array(selectedPlayerIds))
                    }
                } label: {
                    Text("Save Attendance")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(AppTheme.accent)
                        .cornerRadius(10)
                }
            }
        }
        .cardStyle()
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
    }
}
