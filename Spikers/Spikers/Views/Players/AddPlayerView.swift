import SwiftUI

// MARK: - Add Player View
struct AddPlayerView: View {
    @Bindable var viewModel: PlayersViewModel
    @Environment(\.dismiss) private var dismiss

    // Common sports/fun emojis to pick from
    private let emojiOptions = [
        "🏐", "⚡", "🔥", "🌟", "💪", "🎯", "🦅", "🐺",
        "🦁", "🐻", "🦈", "🐉", "👑", "💎", "🎪", "🚀",
        "🌊", "⭐", "🏆", "🎖️", "🥇", "🦇", "🐯", "🦊",
        "🐝", "🦋", "🌸", "🍀", "☀️", "🌈", "❤️", "💙"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Selected emoji preview
                    Text(viewModel.newPlayerEmoji)
                        .font(.system(size: 64))
                        .frame(width: 100, height: 100)
                        .background(AppTheme.card02)
                        .cornerRadius(50)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Player Name")
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        TextField("Enter name", text: $viewModel.newPlayerName)
                            .textFieldStyle(.roundedBorder)
                            .colorScheme(.dark)
                    }

                    // Emoji picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Emoji")
                            .font(.headline)
                            .foregroundColor(AppTheme.foreground)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    viewModel.newPlayerEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            viewModel.newPlayerEmoji == emoji
                                                ? AppTheme.accent.opacity(0.3)
                                                : AppTheme.card02
                                        )
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    viewModel.newPlayerEmoji == emoji
                                                        ? AppTheme.accent
                                                        : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                            }
                        }
                    }

                    Spacer()

                    // Create button
                    Button {
                        Task {
                            let success = await viewModel.createPlayer()
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
                            Text("Add Player")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    viewModel.newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? AppTheme.accent.opacity(0.4)
                                        : AppTheme.accent
                                )
                                .cornerRadius(12)
                        }
                    }
                    .disabled(viewModel.isCreating || viewModel.newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("New Player")
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
