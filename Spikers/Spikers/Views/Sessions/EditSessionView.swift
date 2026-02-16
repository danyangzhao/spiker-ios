import SwiftUI

// MARK: - Edit Session View
struct EditSessionView: View {
    @Bindable var viewModel: SessionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        DatePicker(
                            "Session Date",
                            selection: $viewModel.editSessionDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .tint(AppTheme.accent)
                        .colorScheme(.dark)
                    }

                    Spacer()

                    // Save button
                    Button {
                        Task {
                            let success = await viewModel.saveEditedSession()
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isEditingSession {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent.opacity(0.6))
                                .cornerRadius(12)
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(viewModel.isEditingSession)
                }
                .padding()
            }
            .navigationTitle("Edit Session")
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
