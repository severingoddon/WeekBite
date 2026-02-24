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
                if menu.is_own != false {
                    HStack(spacing: 16) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .foregroundStyle(WBColor.textSecondary)
                                .frame(width: 32, height: 32)
                        }
                        Button { showDeleteConfirm = true } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red.opacity(0.7))
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                if !menu.note.isEmpty {
                    Text(menu.note)
                        .font(.system(size: 12))
                        .foregroundStyle(WBColor.textSecondary)
                }
                Text("\(menu.effort_min) Min.")
                    .font(.system(size: 12))
                    .foregroundStyle(WBColor.textMuted)
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
        .confirmationDialog("\(menu.title) löscletzhen?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) { onDelete() }
        } message: {
            Text("Das Menu wird unwiderruflich gelöscht.")
        }
    }
}
