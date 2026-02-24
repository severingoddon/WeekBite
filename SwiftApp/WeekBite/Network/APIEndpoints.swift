import Foundation

enum APIEndpoints {
    static let baseURL = "https://weekbite.goddoni.org:3003"

    // Auth
    static let googleLogin = "/api/auth/google/login?platform=ios"
    static let me = "/api/auth/me"

    // Menus
    static let menus = "/api/menus"
    static func menu(_ id: Int) -> String { "/api/menus/\(id)" }

    // Week
    static let week = "/api/week"
    static func weekDay(_ weekId: Int, _ day: String) -> String { "/api/week/\(weekId)/\(day)" }
    static func resetWeek(_ weekId: Int) -> String { "/api/week/\(weekId)" }
    static let nextWeekExists = "/api/week/next-exists"
    static let nextWeek = "/api/week/next"

    // Shopping
    static let shopping = "/api/shopping"
    static func shoppingItem(_ id: Int) -> String { "/api/shopping/\(id)" }
    static func toggleShopping(_ id: Int) -> String { "/api/shopping/\(id)/toggle" }

    // Families
    static let families = "/api/families"
    static func family(_ id: Int) -> String { "/api/families/\(id)" }
    static func invite(_ familyId: Int) -> String { "/api/families/\(familyId)/invite" }
    static func removeMember(_ familyId: Int, _ userId: Int) -> String { "/api/families/\(familyId)/members/\(userId)" }
    static func acceptInvite(_ inviteId: Int) -> String { "/api/families/invites/\(inviteId)/accept" }
    static func declineInvite(_ inviteId: Int) -> String { "/api/families/invites/\(inviteId)/decline" }

    // Context
    static let context = "/api/context"
}
