import SwiftUI

@Observable
final class TourManager {
    private let welcomeKey = "weekbite_welcome_seen"

    var showWelcome: Bool = false

    func tryShowWelcome() {
        if UserDefaults.standard.bool(forKey: welcomeKey) { return }
        showWelcome = true
    }

    func dismissWelcome() {
        UserDefaults.standard.set(true, forKey: welcomeKey)
        showWelcome = false
    }
}
