import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @State private var groupManager = GroupManager.shared
    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                List {
                    // Current Group
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Group")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)

                            Text(groupManager.currentGroupName ?? "None")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.accent)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(AppTheme.card)

                        ShareLink(
                            item: "Join my Spikers group! The group name is: \(groupManager.currentGroupName ?? "")"
                        ) {
                            Label("Share Group Name", systemImage: "square.and.arrow.up")
                                .foregroundColor(AppTheme.foreground)
                        }
                        .listRowBackground(AppTheme.card)

                        Button {
                            if let name = groupManager.currentGroupName {
                                UIPasteboard.general.string = name
                            }
                        } label: {
                            Label("Copy Group Name", systemImage: "doc.on.doc")
                                .foregroundColor(AppTheme.foreground)
                        }
                        .listRowBackground(AppTheme.card)
                    }

                    // Switch Groups
                    if groupManager.previousGroups.count > 1 {
                        Section("Switch Group") {
                            ForEach(groupManager.previousGroups, id: \.["id"]) { group in
                                let isActive = group["id"] == groupManager.currentGroupId
                                Button {
                                    if let id = group["id"], let name = group["name"] {
                                        groupManager.switchToGroup(id: id, name: name)
                                    }
                                } label: {
                                    HStack {
                                        Text(group["name"] ?? "Unknown")
                                            .foregroundColor(AppTheme.foreground)
                                        Spacer()
                                        if isActive {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(AppTheme.accent)
                                        }
                                    }
                                }
                                .listRowBackground(AppTheme.card)
                            }
                        }
                    }

                    // Join or Create
                    Section {
                        Button {
                            showJoinSheet = true
                        } label: {
                            Label("Join Another Group", systemImage: "person.badge.plus")
                                .foregroundColor(AppTheme.foreground)
                        }
                        .listRowBackground(AppTheme.card)

                        Button {
                            showCreateSheet = true
                        } label: {
                            Label("Create New Group", systemImage: "plus.circle")
                                .foregroundColor(AppTheme.foreground)
                        }
                        .listRowBackground(AppTheme.card)
                    }

                    // About
                    Section {
                        Link(destination: URL(string: "https://spikers-production.up.railway.app/privacy")!) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                                .foregroundColor(AppTheme.foreground)
                        }
                        .listRowBackground(AppTheme.card)

                        HStack {
                            Text("Version")
                                .foregroundColor(AppTheme.secondaryText)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .listRowBackground(AppTheme.card)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showJoinSheet) {
                SettingsJoinGroupSheet(isPresented: $showJoinSheet)
            }
            .sheet(isPresented: $showCreateSheet) {
                SettingsCreateGroupSheet(isPresented: $showCreateSheet)
            }
        }
    }
}

// MARK: - Join Group Sheet (from Settings)
struct SettingsJoinGroupSheet: View {
    @Binding var isPresented: Bool
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let groupService = GroupService()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Type the group name to join")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)

                    TextField("e.g. FRIENDZ", text: $groupName)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(AppTheme.card02)
                        .foregroundColor(AppTheme.foreground)
                        .cornerRadius(12)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Button {
                        Task { await joinGroup() }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity).padding()
                        } else {
                            Text("Join Group")
                                .font(.headline)
                                .frame(maxWidth: .infinity).padding()
                        }
                    }
                    .background(groupName.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.card03 : AppTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private func joinGroup() async {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        do {
            let group = try await groupService.joinGroup(name: trimmed)
            GroupManager.shared.setGroup(group)
            isPresented = false
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
        isLoading = false
    }
}

// MARK: - Create Group Sheet (from Settings)
struct SettingsCreateGroupSheet: View {
    @Binding var isPresented: Bool
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let groupService = GroupService()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Pick a unique group name")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)

                    TextField("e.g. BEACH BUMZ", text: $groupName)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(AppTheme.card02)
                        .foregroundColor(AppTheme.foreground)
                        .cornerRadius(12)

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    Spacer()

                    Button {
                        Task { await createGroup() }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity).padding()
                        } else {
                            Text("Create Group")
                                .font(.headline)
                                .frame(maxWidth: .infinity).padding()
                        }
                    }
                    .background(groupName.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.card03 : AppTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private func createGroup() async {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        do {
            let group = try await groupService.createGroup(name: trimmed)
            GroupManager.shared.setGroup(group)
            isPresented = false
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
        isLoading = false
    }
}
