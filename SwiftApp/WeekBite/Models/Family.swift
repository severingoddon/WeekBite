import Foundation

struct FamilyMember: Codable, Identifiable {
    let user_id: Int
    let email: String
    let name: String?
    let picture: String?

    var id: Int { user_id }
}

struct Family: Codable, Identifiable {
    let id: Int
    let name: String
    let created_by: Int
    let members: [FamilyMember]
}

struct FamilyCreate: Codable {
    let name: String
}

struct PendingInvite: Codable, Identifiable {
    let id: Int
    let family_id: Int
    let family_name: String
    let invited_by: String?
}
