import Foundation

@Observable
final class UserContextViewModel {
    var user: UserInfo?
    var contextVersion: Int = 0
    var refreshVersion: Int = 0

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    var activeContextName: String {
        guard let user else { return "Privat" }
        if let familyId = user.active_family_id,
           let family = user.families.first(where: { $0.id == familyId }) {
            return family.name
        }
        return "Privat"
    }

    func loadUser() async {
        do {
            user = try await api.getMe()
        } catch {
            user = nil
        }
    }

    func switchContext(familyId: Int?) async {
        do {
            try await api.switchContext(familyId: familyId)
            await loadUser()
            contextVersion += 1
        } catch {}
    }
}
