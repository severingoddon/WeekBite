import SwiftUI

struct ContextSwitcherMenu: View {
    @Environment(UserContextViewModel.self) private var userContext

    var body: some View {
        Menu {
            Button {
                Task { await userContext.switchContext(familyId: nil) }
            } label: {
                Label("Privat", systemImage: "person")
            }

            if let user = userContext.user, !user.families.isEmpty {
                Divider()
                ForEach(user.families) { family in
                    Button {
                        Task { await userContext.switchContext(familyId: family.id) }
                    } label: {
                        Label(family.name, systemImage: "person.3")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: userContext.user?.active_family_id != nil ? "person.3" : "person")
                    .font(.system(size: 12))
                    .foregroundStyle(WBColor.accentCyan)
                Text(userContext.activeContextName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WBColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(WBColor.textMuted)
            }
        }
        .tourAnchor("context-switcher")
    }
}
