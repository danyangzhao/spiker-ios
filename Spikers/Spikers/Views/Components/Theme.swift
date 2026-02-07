import SwiftUI

// MARK: - App Theme
/// Color palette matching the web app's dark theme
enum AppTheme {
    // Main colors
    static let background = Color(red: 20/255, green: 18/255, blue: 11/255)     // #14120b
    static let foreground = Color(red: 237/255, green: 236/255, blue: 236/255)   // #edecec
    static let accent = Color(red: 245/255, green: 78/255, blue: 0/255)          // #f54e00

    // Card backgrounds (progressively lighter)
    static let card = Color(red: 27/255, green: 25/255, blue: 19/255)            // #1b1913
    static let card01 = Color(red: 29/255, green: 27/255, blue: 21/255)          // #1d1b15
    static let card02 = Color(red: 32/255, green: 30/255, blue: 24/255)          // #201e18
    static let card03 = Color(red: 38/255, green: 36/255, blue: 30/255)          // #26241e
    static let card04 = Color(red: 43/255, green: 41/255, blue: 35/255)          // #2b2923

    // Secondary text (60% opacity)
    static let secondaryText = foreground.opacity(0.6)

    // Status colors
    static let live = Color.green
    static let upcoming = Color.blue
    static let completed = Color.gray

    // Win/Loss colors
    static let win = Color.green
    static let loss = Color.red
}

// MARK: - Card Style Modifier
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppTheme.card)
            .cornerRadius(16)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
