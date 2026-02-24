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
                Text(userContext.activeContextName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(WBColor.textPrimary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(WBColor.textSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(WBColor.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(WBColor.borderSubtle, lineWidth: 1)
            )
        }
        .tourAnchor("context-switcher")
    }
}
