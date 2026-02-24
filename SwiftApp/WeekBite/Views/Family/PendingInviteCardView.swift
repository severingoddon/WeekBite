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
            HStack(spacing: 8) {
                GradientButton(title: "Annehmen", action: onAccept)
                OutlineButton(title: "Ablehnen", action: onDecline)
            }
        }
        .padding(14)
        .cardStyle()
    }
}
