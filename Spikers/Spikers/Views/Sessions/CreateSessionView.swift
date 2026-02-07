import SwiftUI

// MARK: - Create Session View
struct CreateSessionView: View {
    @Bindable var viewModel: SessionsViewModel
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
                            selection: $viewModel.newSessionDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .tint(AppTheme.accent)
                        .colorScheme(.dark)
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location (optional)")
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        TextField("e.g. Central Park", text: $viewModel.newSessionLocation)
                            .textFieldStyle(.roundedBorder)
                            .colorScheme(.dark)
                    }

                    Spacer()

                    // Create button
                    Button {
                        Task {
                            let success = await viewModel.createSession()
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent.opacity(0.6))
                                .cornerRadius(12)
                        } else {
                            Text("Create Session")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accent)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(viewModel.isCreating)
                }
                .padding()
            }
            .navigationTitle("New Session")
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
