import SwiftUI

struct ToastMessage: Equatable {
    let text: String
    let actionLabel: String?
    let action: (() -> Void)?

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.text == rhs.text && lhs.actionLabel == rhs.actionLabel
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let toast {
                HStack(spacing: 12) {
                    Text(toast.text)
                        .font(.system(size: 14))
                        .foregroundStyle(WBColor.textPrimary)

                    if let label = toast.actionLabel {
                        Button(label) {
                            toast.action?()
                            self.toast = nil
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WBColor.accentCyan)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(WBColor.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(WBColor.borderSubtle, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { self.toast = nil }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}
