import SwiftUI

// MARK: - Stat Card
/// A card that shows a single stat with a label and value
struct StatCard: View {
    let label: String
    let value: String
    var valueColor: Color = AppTheme.foreground

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(valueColor)

            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(AppTheme.card02)
        .cornerRadius(12)
    }
}

// MARK: - Stat Row
/// A horizontal row showing label and value, for lists of stats
struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = AppTheme.foreground

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}
