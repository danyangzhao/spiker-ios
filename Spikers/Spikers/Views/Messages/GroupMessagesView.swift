import SwiftUI

// MARK: - Group Messages View
struct GroupMessagesView: View {
    @State private var viewModel = GroupMessagesViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.messages.isEmpty {
                    LoadingView(message: "Loading messages...")
                } else if let error = viewModel.errorMessage, viewModel.messages.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadData() }
                    }
                } else if viewModel.messages.isEmpty {
                    EmptyStateView(
                        icon: "megaphone",
                        title: "No Messages Yet",
                        message: "Post a message to notify your group about an upcoming session!"
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if let cooldownText = viewModel.cooldownText {
                                CooldownBanner(text: cooldownText)
                            }

                            if let result = viewModel.submitResultMessage {
                                ResultBanner(text: result)
                            }

                            ForEach(viewModel.messages) { message in
                                MessageCard(message: message) {
                                    viewModel.startEditing(message)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.loadData()
                    }
                }
            }
            .navigationTitle("Messages")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showComposeSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showComposeSheet) {
                ComposeMessageSheet(viewModel: viewModel)
            }
            .sheet(item: $viewModel.editingMessage) { _ in
                EditMessageSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Cooldown Banner
struct CooldownBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(AppTheme.secondaryText)
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(AppTheme.card02)
        .cornerRadius(10)
    }
}

// MARK: - Result Banner
struct ResultBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.foreground)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(AppTheme.card02)
        .cornerRadius(10)
    }
}

// MARK: - Message Card
struct MessageCard: View {
    let message: GroupMessage
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.author.emoji)
                    .font(.title3)
                Text(message.author.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.secondaryText)
                Spacer()
                Text(formatRelativeDate(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Text(message.title)
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            Text(message.body)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                if message.pushSentAt != nil {
                    Label("Push sent", systemImage: "bell.fill")
                        .font(.caption2)
                        .foregroundColor(AppTheme.accent)
                } else {
                    Label("No push", systemImage: "bell.slash")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }

                Spacer()

                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption2)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .padding(12)
        .background(AppTheme.card)
        .cornerRadius(12)
    }

    private func formatRelativeDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return dateString }

        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Compose Message Sheet
struct ComposeMessageSheet: View {
    @Bindable var viewModel: GroupMessagesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let cooldownText = viewModel.cooldownText {
                            CooldownBanner(text: cooldownText)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Who are you?")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(viewModel.players) { player in
                                        Button {
                                            viewModel.selectedAuthorId = player.id
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(player.emoji)
                                                Text(player.name)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                viewModel.selectedAuthorId == player.id
                                                    ? AppTheme.accent
                                                    : AppTheme.card02
                                            )
                                            .foregroundColor(AppTheme.foreground)
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)

                            TextField("e.g. Session This Saturday!", text: $viewModel.composeTitle)
                                .font(.body)
                                .padding()
                                .background(AppTheme.card02)
                                .foregroundColor(AppTheme.foreground)
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)

                            TextField(
                                "e.g. We're playing at Riverside Park at 2pm. RSVP in the app!",
                                text: $viewModel.composeBody,
                                axis: .vertical
                            )
                            .lineLimit(3...6)
                            .font(.body)
                            .padding()
                            .background(AppTheme.card02)
                            .foregroundColor(AppTheme.foreground)
                            .cornerRadius(10)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button {
                            Task { await viewModel.createMessage() }
                        } label: {
                            if viewModel.isSubmitting {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity).padding()
                            } else {
                                Text("Post Message")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity).padding()
                            }
                        }
                        .background(isFormValid ? AppTheme.accent : AppTheme.card03)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .disabled(!isFormValid || viewModel.isSubmitting)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !viewModel.composeTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !viewModel.composeBody.trimmingCharacters(in: .whitespaces).isEmpty &&
        viewModel.selectedAuthorId != nil
    }
}

// MARK: - Edit Message Sheet
struct EditMessageSheet: View {
    @Bindable var viewModel: GroupMessagesViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Editing will not send a new push notification.")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)

                            TextField("Title", text: $viewModel.editTitle)
                                .font(.body)
                                .padding()
                                .background(AppTheme.card02)
                                .foregroundColor(AppTheme.foreground)
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)

                            TextField("Message", text: $viewModel.editBody, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.body)
                                .padding()
                                .background(AppTheme.card02)
                                .foregroundColor(AppTheme.foreground)
                                .cornerRadius(10)
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Button {
                            Task {
                                if await viewModel.saveEdit() {
                                    dismiss()
                                }
                            }
                        } label: {
                            if viewModel.isEditing {
                                ProgressView().tint(.white)
                                    .frame(maxWidth: .infinity).padding()
                            } else {
                                Text("Save Changes")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity).padding()
                            }
                        }
                        .background(isEditValid ? AppTheme.accent : AppTheme.card03)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .disabled(!isEditValid || viewModel.isEditing)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.editingMessage = nil
                        dismiss()
                    }
                }
            }
        }
    }

    private var isEditValid: Bool {
        !viewModel.editTitle.trimmingCharacters(in: .whitespaces).isEmpty &&
        !viewModel.editBody.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
