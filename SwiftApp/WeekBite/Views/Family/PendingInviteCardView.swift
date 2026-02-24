import SwiftUI

struct PendingInviteCardView: View {
    let invite: PendingInvite
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invite.family_name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(WBColor.textPrimary)
                if let invitedBy = invite.invited_by {
                    Text("Eingeladen von \(invitedBy)")
                        .font(.system(size: 12))
                        .foregroundStyle(WBColor.textSecondary)
                }
            }
            Spacer()
            HStack(spacing: 16) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(WBColor.textMuted)
                        .frame(width: 36, height: 36)
                        .background(WBColor.bgElevated)
                        .clipShape(Circle())
                }
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            LinearGradient(
                                colors: [WBColor.accentCyan, WBColor.accentViolet],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(Circle())
                }
            }
        }
        .padding(14)
        .cardStyle()
    }
}
