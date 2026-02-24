import Foundation
import AuthenticationServices

@Observable
final class AuthManager {
    var isLoggedIn: Bool = false
    var token: String?

    init() {
        if let saved = KeychainHelper.getToken() {
            self.token = saved
            self.isLoggedIn = true
        }
    }

    func saveToken(_ token: String) {
        KeychainHelper.saveToken(token)
        self.token = token
        self.isLoggedIn = true
    }

    func logout() {
        KeychainHelper.deleteToken()
        self.token = nil
        self.isLoggedIn = false
    }

    func startGoogleLogin() -> URL? {
        URL(string: APIEndpoints.baseURL + APIEndpoints.googleLogin)
    }
}
