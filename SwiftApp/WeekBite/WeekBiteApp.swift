import SwiftUI

@main
struct WeekBiteApp: App {
    @State private var authManager = AuthManager()
    @State private var apiClient = APIClient()
    @State private var tourManager = TourManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
                .environment(apiClient)
                .environment(tourManager)
                .onAppear {
                    apiClient.authManager = authManager
                }
                .onOpenURL { url in
                    handleCallback(url)
                }
                .overlay {
                    WelcomeOverlayView()
                        .environment(tourManager)
                }
                .preferredColorScheme(.dark)
        }
    }

    private func handleCallback(_ url: URL) {
        guard url.scheme == "weekbite",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value
        else { return }
        authManager.saveToken(token)
    }
}
