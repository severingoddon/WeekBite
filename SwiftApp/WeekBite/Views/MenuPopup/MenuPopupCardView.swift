import SwiftUI

struct MenuPopupCardView: View {
    let menu: MenuModel
    let isExpanded: Bool
    let onSelect: () -> Void
    let onToggleDetails: () -> Void
    let onAddToShopping: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(menu.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(WBColor.textPrimary)
                        HStack(spacing: 4) {
                            Text("\(menu.ingredients.count) Zutaten · \(menu.effort_min) Min.")
                                .font(.system(size: 12))
                                .foregroundStyle(WBColor.textSecondary)
                            if !menu.link.isEmpty, let url = URL(string: menu.link) {
                                Link(destination: url) {
                                    Image(systemName: "link")
                                        .font(.system(size: 12))
                                        .foregroundStyle(WBColor.accentCyan)
                                }
                            }
                        }
                    }
                    Spacer()
                    Button {
                        onToggleDetails()
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(WBColor.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if !menu.note.isEmpty {
                        menu.note.linkHighlighted(baseColor: WBColor.textSecondary)
                            .font(.system(size: 13))
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 13))
                            .foregroundStyle(WBColor.textMuted)
                        Text("\(menu.effort_min) Minuten")
                            .font(.system(size: 13))
                            .foregroundStyle(WBColor.textSecondary)
                    }

                    FlowLayout(spacing: 6) {
                        ForEach(Array(menu.ingredients.enumerated()), id: \.offset) { index, ingredient in
                            Button {
                                onAddToShopping(ingredient)
                            } label: {
                                HStack(spacing: 4) {
                                    Text(ingredient)
                                        .font(.system(size: 13))
                                    Image(systemName: "plus")
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(WBColor.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(WBColor.bgActive)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .cardStyle()
    }
}

// Simple flow layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
