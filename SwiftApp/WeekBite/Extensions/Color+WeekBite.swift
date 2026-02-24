import SwiftUI

extension View {
    func gradientForeground() -> some View {
        overlay(WBColor.gradient)
            .mask(self)
    }
}

struct GradientText: View {
    let text: String
    var font: Font = .system(size: 22, weight: .bold)

    var body: some View {
        Text(text)
            .font(font)
            .gradientForeground()
    }
}
