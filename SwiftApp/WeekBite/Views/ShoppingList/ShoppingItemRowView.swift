import SwiftUI

struct ShoppingItemRowView: View {
    let item: ShoppingItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.checked ? WBColor.accentCyan : WBColor.textMuted)
                    .font(.system(size: 20))

                HStack(spacing: 4) {
                    if !item.quantity.isEmpty {
                        Text(item.quantity)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(item.checked ? WBColor.textMuted : WBColor.accentCyan)
                    }
                    Text(item.name)
                        .font(.system(size: 14))
                        .foregroundStyle(item.checked ? WBColor.textMuted : WBColor.textPrimary)
                        .strikethrough(item.checked)
                }

                Spacer()

                HStack(spacing: 4) {
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundStyle(WBColor.textMuted)
                    }
                    .buttonStyle(.plain)

                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundStyle(WBColor.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(item.checked ? 0.6 : 1)
    }
}
