import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        ZStack {
            WBColor.bgDeepest.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo
                ZStack {
                    Circle()
                        .stroke(WBColor.gradient, lineWidth: 2.5)
                        .frame(width: 80, height: 80)
                    Text("W")
                        .font(.system(size: 36, weight: .bold))
                        .gradientForeground()
                }

                VStack(spacing: 8) {
                    GradientText(text: "WeekBite", font: .system(size: 32, weight: .bold))
                    Text("Plane deine Woche, verwalte Menus\nund erstelle Einkaufslisten.")
                        .font(.system(size: 15))
                        .foregroundStyle(WBColor.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Button {
                    startGoogleLogin()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                        Text("Mit Google anmelden")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(WBColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 60)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func startGoogleLogin() {
        guard let loginURL = authManager.startGoogleLogin() else { return }

        let session = ASWebAuthenticationSession(
            url: loginURL,
            callbackURLScheme: "weekbite"
        ) { callbackURL, error in
            guard let callbackURL, error == nil else { return }
            if let token = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "token" })?.value {
                authManager.saveToken(token)
            }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = LoginPresentationContext.shared
        session.start()
    }
}

final class LoginPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = LoginPresentationContext()
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
}
