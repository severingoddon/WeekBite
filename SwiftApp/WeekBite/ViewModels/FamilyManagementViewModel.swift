import Foundation

@Observable
final class FamilyManagementViewModel {
    var families: [Family] = []
    var pendingInvites: [PendingInvite] = []
    var newFamilyName: String = ""
    var inviteEmails: [Int: String] = [:]
    var editingFamilyId: Int?
    var editFamilyName: String = ""
    var userEmail: String = ""

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func loadData() async {
        do {
            let user = try await api.getMe()
            userEmail = user.email
            families = user.families
            pendingInvites = user.pending_invites
        } catch {}
    }

    func createFamily() async -> String? {
        let name = newFamilyName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        do {
            _ = try await api.createFamily(FamilyCreate(name: name))
            newFamilyName = ""
            await loadData()
            return "Familie erstellt"
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func startRename(_ family: Family) {
        editingFamilyId = family.id
        editFamilyName = family.name
    }

    func saveRename(_ family: Family) async -> String? {
        let name = editFamilyName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        do {
            _ = try await api.updateFamily(family.id, FamilyCreate(name: name))
            editingFamilyId = nil
            await loadData()
            return "Familie umbenannt"
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func cancelRename() {
        editingFamilyId = nil
    }

    func deleteFamily(_ family: Family) async -> String? {
        do {
            try await api.deleteFamily(family.id)
            await loadData()
            return "Familie gelöscht"
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func leaveFamily(_ family: Family) async -> String? {
        guard let userId = getUserId(family) else { return nil }
        do {
            try await api.removeFamilyMember(family.id, userId: userId)
            await loadData()
            return "Familie verlassen"
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func inviteMember(_ family: Family) async -> String? {
        let email = (inviteEmails[family.id] ?? "").trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else { return nil }
        do {
            let res = try await api.inviteToFamily(family.id, email: email)
            inviteEmails[family.id] = ""
            await loadData()
            return res.detail ?? "Einladung gesendet"
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func removeMember(_ family: Family, userId: Int) async -> String? {
        do {
            try await api.removeFamilyMember(family.id, userId: userId)
            await loadData()
            return "Mitglied entfernt"
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func isCreator(_ family: Family) -> Bool {
        getUserId(family) == family.created_by
    }

    func isActive(_ family: Family, activeId: Int?) -> Bool {
        activeId == family.id
    }

    func acceptInvite(_ invite: PendingInvite) async -> String? {
        do {
            try await api.acceptInvite(invite.id)
            await loadData()
            return "Einladung zu \"\(invite.family_name)\" angenommen"
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func declineInvite(_ invite: PendingInvite) async -> String? {
        do {
            try await api.declineInvite(invite.id)
            await loadData()
            return "Einladung abgelehnt"
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func api_switchContext(_ familyId: Int?) async throws {
        try await api.switchContext(familyId: familyId)
    }

    private func getUserId(_ family: Family) -> Int? {
        family.members.first(where: { $0.email == userEmail })?.user_id
    }
}
