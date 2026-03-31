import SwiftUI

// MARK: - Onboarding View
/// Shown on first launch when no group is selected.
/// Users can create a new group or join an existing one.
struct OnboardingView: View {
    @State private var screen: OnboardingScreen = .welcome

    enum OnboardingScreen {
        case welcome
        case create
        case join
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            switch screen {
            case .welcome:
                WelcomeScreen(
                    onCreateTapped: { screen = .create },
                    onJoinTapped: { screen = .join }
                )
            case .create:
                CreateGroupScreen(onBack: { screen = .welcome })
            case .join:
                JoinGroupScreen(onBack: { screen = .welcome })
            }
        }
    }
}

// MARK: - Spikeball Icon
struct SpikeballIcon: View {
    let size: CGFloat

    private var ballYellow: Color { Color(red: 1.0, green: 0.82, blue: 0.05) }
    private var ballYellowDark: Color { Color(red: 0.85, green: 0.65, blue: 0.0) }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [ballYellow, ballYellowDark],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: size * 0.05,
                        endRadius: size * 0.65
                    )
                )
                .frame(width: size, height: size)

            Circle()
                .stroke(ballYellowDark, lineWidth: size * 0.03)
                .frame(width: size, height: size)

            ForEach([0.0, 60.0, 120.0], id: \.self) { angle in
                Ellipse()
                    .stroke(ballYellowDark.opacity(0.5), lineWidth: size * 0.025)
                    .frame(width: size * 0.88, height: size * 0.35)
                    .rotationEffect(.degrees(angle))
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.45), Color.clear],
                        center: UnitPoint(x: 0.3, y: 0.25),
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.85, height: size * 0.85)
        }
        .shadow(color: ballYellowDark.opacity(0.4), radius: 12, y: 6)
    }
}

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    let onCreateTapped: () -> Void
    let onJoinTapped: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                SpikeballIcon(size: 88)
                    .padding(.bottom, 4)

                Text("Local Spikers")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.foreground)

                Text("Track every round net session\nwith your crew")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 14) {
                Button(action: onCreateTapped) {
                    Text("Create a Group")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button(action: onJoinTapped) {
                    Text("Join a Group")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.card02)
                        .foregroundColor(AppTheme.foreground)
                        .cornerRadius(14)
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Create Group Screen
struct CreateGroupScreen: View {
    let onBack: () -> Void

    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var createdGroup: Group?

    private let groupService = GroupService()

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(AppTheme.foreground)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                Text("Name Your Group")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.foreground)

                Text("Pick something fun and unique.\nThis is what friends will type to join!")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let group = createdGroup {
                // Success state
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 56))

                    Text("Group created!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.foreground)

                    Text("Tell your friends to join:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)

                    Text(group.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accent)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.card02)
                        .cornerRadius(12)

                    ShareLink(item: "Join my Spikers group! The group name is: \(group.name)") {
                        Label("Share with Friends", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.card02)
                            .foregroundColor(AppTheme.foreground)
                            .cornerRadius(14)
                    }
                }

                Spacer()

                Button {
                    GroupManager.shared.setGroup(group)
                } label: {
                    Text("Let's Go!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.bottom, 40)
            } else {
                // Input state
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
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Create Group")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(groupName.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.card03 : AppTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(14)
                .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .padding(.bottom, 40)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private func createGroup() async {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let group = try await groupService.createGroup(name: trimmed)
            createdGroup = group
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
    }
}

// MARK: - Join Group Screen
struct JoinGroupScreen: View {
    let onBack: () -> Void

    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let groupService = GroupService()

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(AppTheme.foreground)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                Text("Join a Group")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.foreground)

                Text("Type the group name\nyour friend shared with you")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }

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
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Join Group")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(groupName.trimmingCharacters(in: .whitespaces).isEmpty ? AppTheme.card03 : AppTheme.accent)
            .foregroundColor(.white)
            .cornerRadius(14)
            .disabled(groupName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private func joinGroup() async {
        let trimmed = groupName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let group = try await groupService.joinGroup(name: trimmed)
            GroupManager.shared.setGroup(group)
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
    }
}
