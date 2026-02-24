import Foundation

struct ShoppingItem: Codable, Identifiable {
    let id: Int
    let name: String
    let quantity: String
    let checked: Bool
    let created: Bool?
}

struct ShoppingItemCreate: Codable {
    let name: String
    let quantity: String
}
