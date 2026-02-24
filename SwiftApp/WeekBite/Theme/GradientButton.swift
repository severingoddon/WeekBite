import SwiftUI

struct GradientButton: View {
    let title: String
    let action: () -> Void
    var disabled: Bool = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    disabled
                        ? AnyShapeStyle(Color.gray.opacity(0.3))
                        : AnyShapeStyle(WBColor.gradient)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(disabled)
    }
}

struct OutlineButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(WBColor.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(WBColor.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(WBColor.borderSubtle, lineWidth: 1)
            )
        }
    }
}
