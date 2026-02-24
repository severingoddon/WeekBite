import SwiftUI

struct CardStyle: ViewModifier {
    var isWeekend: Bool = false

    func body(content: Content) -> some View {
        content
            .background(isWeekend ? WBColor.bgWeekend : WBColor.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(WBColor.borderSubtle, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
    }
}

extension View {
    func cardStyle(isWeekend: Bool = false) -> some View {
        modifier(CardStyle(isWeekend: isWeekend))
    }
}
