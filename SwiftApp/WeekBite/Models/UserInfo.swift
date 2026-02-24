import Foundation

struct UserInfo: Codable {
    let email: String
    let name: String?
    let avatar_letter: String
    let picture: String?
    let is_admin: Bool
    let active_family_id: Int?
    let families: [Family]
    let pending_invites: [PendingInvite]
}
