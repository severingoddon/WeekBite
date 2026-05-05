import SwiftUI

struct MenuCardView: View {
    let menu: MenuModel
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(menu.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(WBColor.textPrimary)
                    if let ownerName = menu.owner_name {
                        Text("von \(ownerName)")
                            .font(.system(size: 12))
                            .foregroundStyle(WBColor.textMuted)
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("\(menu.effort_min) Min.")
                        .font(.system(size: 12))
                        .foregroundStyle(WBColor.textMuted)
                    if !menu.link.isEmpty, let url = URL(string: menu.link) {
                        Link(destination: url) {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundStyle(WBColor.accentCyan)
                        } 
                    }
                }
            }

            if !menu.note.isEmpty {
                menu.note.linkHighlighted(baseColor: WBColor.textSecondary)
                    .font(.system(size: 12))
            }

            if !menu.ingredients.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(menu.ingredients, id: \.self) { ingredient in
                        Text(ingredient)
                            .font(.system(size: 12))
                            .foregroundStyle(WBColor.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(WBColor.bgActive)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding(14)
        .cardStyle()
        .opacity(menu.is_own == false ? 0.7 : 1)
        .contentShape(Rectangle())
        .contextMenu {
            if menu.is_own != false {
                Button {
                    onEdit()
                } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            }
        }
        .confirmationDialog("\(menu.title) löschen?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) { onDelete() }
        } message: {
            Text("Das Menu wird unwiderruflich gelöscht.")
        }
    }
}
