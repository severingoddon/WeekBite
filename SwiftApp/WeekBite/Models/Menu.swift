import Foundation

struct MenuModel: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let ingredients: [String]
    let note: String
    let effort_min: Int
    let is_own: Bool?
    let owner_name: String?
}

struct MenuCreate: Codable {
    let title: String
    let ingredients: [String]
    let note: String
    let effort_min: Int
}
