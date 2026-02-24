import SwiftUI

struct WelcomeOverlayView: View {
    @Environment(TourManager.self) private var tourManager

    var body: some View {
        if tourManager.showWelcome {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Logo
                    ZStack {
                        Circle()
                            .stroke(WBColor.gradient, lineWidth: 2.5)
                            .frame(width: 48, height: 48)
                        Text("W")
                            .font(.system(size: 22, weight: .bold))
                            .gradientForeground()
                    }

                    GradientText(text: "Willkommen bei WeekBite!", font: .system(size: 20, weight: .bold))

                    Text("Plane deine Woche, verwalte Menus und erstelle Einkaufslisten – alleine oder zusammen mit deiner Familie.")
                        .font(.system(size: 14))
                        .foregroundStyle(WBColor.textSecondary)
                        .multilineTextAlignment(.center)

                    GradientButton(title: "Los geht's") {
                        tourManager.dismissWelcome()
                    }
                }
                .padding(32)
                .background(WBColor.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(WBColor.borderSubtle, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20)
                .padding(32)
            }
            .transition(.opacity)
        }
    }
}
