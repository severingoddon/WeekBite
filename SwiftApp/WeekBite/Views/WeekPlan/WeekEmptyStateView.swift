import SwiftUI

struct WeekEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(WBColor.textMuted)
            Text("Noch kein Wochenplan vorhanden")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(WBColor.textPrimary)
            Text("Wechsle zur aktuellen Woche, um automatisch einen Plan zu erstellen.")
                .font(.system(size: 14))
                .foregroundStyle(WBColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
