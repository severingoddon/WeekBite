import SwiftUI

struct UserAvatarMenu: View {
    @Environment(UserContextViewModel.self) private var userContext
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Menu {
            if let user = userContext.user {
                Text(user.email)
                    .font(.system(size: 13))
                Divider()
            }
            Button(role: .destructive) {
                authManager.logout()
            } label: {
                Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            avatarView
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let user = userContext.user {
            if let picture = user.picture, let url = URL(string: picture) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    avatarLetter(user.avatar_letter)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                avatarLetter(user.avatar_letter)
            }
        } else {
            Image(systemName: "person.circle")
                .font(.system(size: 24))
                .foregroundStyle(WBColor.textSecondary)
        }
    }

    private func avatarLetter(_ letter: String) -> some View {
        ZStack {
            Circle()
                .fill(WBColor.bgElevated)
                .frame(width: 32, height: 32)
            Text(letter)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(WBColor.textPrimary)
        }
    }
}
