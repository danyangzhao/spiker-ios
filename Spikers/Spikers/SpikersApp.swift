import SwiftUI
import UserNotifications

// MARK: - Deep Link Join Sheet
/// Shown when a user opens a deep link to join a group.
struct DeepLinkJoinSheet: View {
    let groupName: String
    @Binding var isPresented: Bool
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let groupService = GroupService()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    SpikeballIcon(size: 64)

                    Text("Join Group")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.foreground)

                    Text(groupName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accent)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.card02)
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
                            Text("Join \(groupName)")
                                .font(.headline)
                                .frame(maxWidth: .infinity).padding()
                        }
                    }
                    .background(AppTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .disabled(isLoading)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private func joinGroup() async {
        isLoading = true
        errorMessage = nil
        do {
            let group = try await groupService.joinGroup(name: groupName)
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

// MARK: - App Delegate
/// The AppDelegate handles system-level events that SwiftUI can't handle directly.
/// For push notifications, iOS sends the device token through the AppDelegate.
class AppDelegate: NSObject, UIApplicationDelegate {

    /// Called when the app successfully registers with Apple Push Notification service (APNs).
    /// APNs gives us a device token (a unique ID for sending notifications to this device).
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.handleDeviceToken(deviceToken)
    }

    /// Called if registration with APNs fails (e.g., no internet, simulator, etc.).
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.handleRegistrationError(error)
    }
}

// MARK: - App Entry Point
@main
struct SpikersApp: App {
    // Connect the AppDelegate so iOS can send us push notification events
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var deepLinkGroupName: String?
    @State private var showDeepLinkSheet = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .task {
                    UNUserNotificationCenter.current().delegate = NotificationManager.shared
                    await NotificationManager.shared.checkPermissionStatus()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .sheet(isPresented: $showDeepLinkSheet) {
                    if let name = deepLinkGroupName {
                        DeepLinkJoinSheet(groupName: name, isPresented: $showDeepLinkSheet)
                    }
                }
        }
    }

    /// Parses URLs like https://spikers-production.up.railway.app/join/GROUPNAME
    private func handleDeepLink(_ url: URL) {
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 3,
              pathComponents[1] == "join" else { return }

        let groupName = pathComponents[2].uppercased()
        deepLinkGroupName = groupName
        showDeepLinkSheet = true
    }
}
