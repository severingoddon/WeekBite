import SwiftUI

enum WBColor {
    static let bgDeepest = Color(hex: 0x0D1117)
    static let bgCard = Color(hex: 0x161B22)
    static let bgHover = Color(hex: 0x1C2330)
    static let bgActive = Color(hex: 0x242D3A)
    static let bgElevated = Color(hex: 0x1F2937)
    static let bgWeekend = Color(hex: 0x1A2233)

    static let accentCyan = Color(hex: 0x06B6D4)
    static let accentViolet = Color(hex: 0x8B5CF6)

    static let textPrimary = Color(hex: 0xE2E8F0)
    static let textSecondary = Color(hex: 0x94A3B8)
    static let textMuted = Color(hex: 0x64748B)

    static let borderSubtle = Color.white.opacity(0.06)
    static let borderHover = Color(hex: 0x06B6D4).opacity(0.3)

    static let gradient = LinearGradient(
        colors: [accentCyan, accentViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
