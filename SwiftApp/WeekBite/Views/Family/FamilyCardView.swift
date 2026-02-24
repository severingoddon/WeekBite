import SwiftUI

struct FamilyCardView: View {
    let family: Family
    @Bindable var viewModel: FamilyManagementViewModel
    let activeId: Int?
    @Binding var toast: ToastMessage?
    let onContextChange: () -> Void

    private var isActive: Bool { viewModel.isActive(family, activeId: activeId) }
    private var isCreator: Bool { viewModel.isCreator(family) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if viewModel.editingFamilyId == family.id {
                    HStack(spacing: 8) {
                        TextField("Name", text: $viewModel.editFamilyName)
                            .textFieldStyle(WBTextFieldStyle())
                            .onSubmit { saveRename() }
                        Button { saveRename() } label: {
                            Image(systemName: "checkmark").foregroundStyle(WBColor.accentCyan)
                        }
                        Button { viewModel.cancelRename() } label: {
                            Image(systemName: "xmark").foregroundStyle(WBColor.textMuted)
                        }
                    }
                } else {
                    Text(family.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WBColor.textPrimary)
                    if isActive {
                        Text("Aktiv")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(WBColor.accentCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(WBColor.accentCyan.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                    if !isActive {
                        OutlineButton(title: "Aktivieren") {
                            viewModel.api_switchContext(family.id)
                            onContextChange()
                        }
                    } else {
                        OutlineButton(title: "Privat") {
                            viewModel.api_switchContext(nil)
                            onContextChange()
                        }
                    }
                    Menu {
                        if isCreator {
                            Button { viewModel.startRename(family) } label: {
                                Label("Umbenennen", systemImage: "pencil")
                            }
                            Button(role: .destructive) { deleteFamily() } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        } else {
                            Button(role: .destructive) { leaveFamily() } label: {
                                Label("Verlassen", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(WBColor.textMuted)
                    }
                }
            }

            Divider().background(WBColor.borderSubtle)

            // Members
            Text("Mitglieder")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(WBColor.textSecondary)

            ForEach(family.members) { member in
                HStack(spacing: 10) {
                    if let picture = member.picture, let url = URL(string: picture) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(WBColor.textMuted)
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(WBColor.textMuted)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(member.name ?? member.email)
                            .font(.system(size: 14))
                            .foregroundStyle(WBColor.textPrimary)
                        Text(member.email)
                            .font(.system(size: 12))
                            .foregroundStyle(WBColor.textMuted)
                    }

                    Spacer()

                    if isCreator && member.user_id != family.created_by {
                        Button {
                            if let msg = viewModel.removeMember(family, userId: member.user_id) {
                                toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                            }
                        } label: {
                            Image(systemName: "person.badge.minus")
                                .foregroundStyle(WBColor.textMuted)
                        }
                    }
                }
            }

            Divider().background(WBColor.borderSubtle)

            // Invite
            HStack(spacing: 8) {
                TextField("E-Mail einladen", text: Binding(
                    get: { viewModel.inviteEmails[family.id] ?? "" },
                    set: { viewModel.inviteEmails[family.id] = $0 }
                ))
                .textFieldStyle(WBTextFieldStyle())
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .onSubmit { inviteMember() }

                GradientButton(
                    title: "Einladen",
                    action: { inviteMember() },
                    disabled: (viewModel.inviteEmails[family.id] ?? "").trimmingCharacters(in: .whitespaces).isEmpty
                )
            }
        }
        .padding(14)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? WBColor.accentCyan.opacity(0.3) : .clear, lineWidth: 1)
        )
    }

    private func saveRename() {
        if let msg = viewModel.saveRename(family) {
            toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
        }
    }

    private func deleteFamily() {
        if let msg = viewModel.deleteFamily(family) {
            toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
        }
        onContextChange()
    }

    private func leaveFamily() {
        if let msg = viewModel.leaveFamily(family) {
            toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
        }
        onContextChange()
    }

    private func inviteMember() {
        if let msg = viewModel.inviteMember(family) {
            toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
        }
    }
}
