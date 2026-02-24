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

    func createFamily() -> String? {
        let name = newFamilyName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        newFamilyName = ""

        Task {
            do {
                _ = try await api.createFamily(FamilyCreate(name: name))
            } catch {}
            await loadData()
        }
        return "Familie erstellt"
    }

    func startRename(_ family: Family) {
        editingFamilyId = family.id
        editFamilyName = family.name
    }

    func saveRename(_ family: Family) -> String? {
        let name = editFamilyName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }

        // Optimistic: update name locally
        if let idx = families.firstIndex(where: { $0.id == family.id }) {
            var updated = families[idx]
            updated = Family(id: updated.id, name: name, created_by: updated.created_by, members: updated.members)
            families[idx] = updated
        }
        editingFamilyId = nil

        Task {
            do {
                _ = try await api.updateFamily(family.id, FamilyCreate(name: name))
            } catch {}
            await loadData()
        }
        return "Familie umbenannt"
    }

    func cancelRename() {
        editingFamilyId = nil
    }

    func deleteFamily(_ family: Family) -> String? {
        // Optimistic: remove locally
        families.removeAll { $0.id == family.id }

        Task {
            try? await api.deleteFamily(family.id)
            await loadData()
        }
        return "Familie gelöscht"
    }

    func leaveFamily(_ family: Family) -> String? {
        guard let userId = getUserId(family) else { return nil }

        // Optimistic: remove locally
        families.removeAll { $0.id == family.id }

        Task {
            try? await api.removeFamilyMember(family.id, userId: userId)
            await loadData()
        }
        return "Familie verlassen"
    }

    func inviteMember(_ family: Family) -> String? {
        let email = (inviteEmails[family.id] ?? "").trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else { return nil }
        inviteEmails[family.id] = ""

        Task {
            do {
                _ = try await api.inviteToFamily(family.id, email: email)
            } catch {}
            await loadData()
        }
        return "Einladung gesendet"
    }

    func removeMember(_ family: Family, userId: Int) -> String? {
        // Optimistic: remove member locally
        if let idx = families.firstIndex(where: { $0.id == family.id }) {
            var updated = families[idx]
            let newMembers = updated.members.filter { $0.user_id != userId }
            families[idx] = Family(id: updated.id, name: updated.name, created_by: updated.created_by, members: newMembers)
        }

        Task {
            try? await api.removeFamilyMember(family.id, userId: userId)
            await loadData()
        }
        return "Mitglied entfernt"
    }

    func isCreator(_ family: Family) -> Bool {
        getUserId(family) == family.created_by
    }

    func isActive(_ family: Family, activeId: Int?) -> Bool {
        activeId == family.id
    }

    func acceptInvite(_ invite: PendingInvite) -> String? {
        // Optimistic: remove from pending
        pendingInvites.removeAll { $0.id == invite.id }

        Task {
            try? await api.acceptInvite(invite.id)
            await loadData()
        }
        return "Einladung zu \"\(invite.family_name)\" angenommen"
    }

    func declineInvite(_ invite: PendingInvite) -> String? {
        // Optimistic: remove from pending
        pendingInvites.removeAll { $0.id == invite.id }

        Task {
            try? await api.declineInvite(invite.id)
            await loadData()
        }
        return "Einladung abgelehnt"
    }

    func api_switchContext(_ familyId: Int?) {
        Task {
            try? await api.switchContext(familyId: familyId)
        }
    }

    private func getUserId(_ family: Family) -> Int? {
        family.members.first(where: { $0.email == userEmail })?.user_id
    }
}
