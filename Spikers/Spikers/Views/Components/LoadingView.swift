import SwiftUI

// MARK: - Loading View
/// A centered loading spinner with optional message
struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accent))
                .scaleEffect(1.2)

            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View
/// Shows an error message with a retry button.
/// Automatically picks a relevant icon and headline based on the error message.
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    /// Choose an SF Symbol icon based on what kind of error this looks like
    private var icon: String {
        if message.lowercased().contains("connect") || message.lowercased().contains("internet") {
            return "wifi.slash"
        }
        if message.lowercased().contains("unexpected response") {
            return "server.rack"
        }
        return "exclamationmark.triangle"
    }

    /// Choose a headline based on what kind of error this looks like
    private var headline: String {
        if message.lowercased().contains("connect") || message.lowercased().contains("internet") {
            return "No Connection"
        }
        if message.lowercased().contains("unexpected response") {
            return "Server Issue"
        }
        return "Something went wrong"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(AppTheme.accent)

            Text(headline)
                .font(.headline)
                .foregroundColor(AppTheme.foreground)

            Text(message)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button(action: onRetry) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
