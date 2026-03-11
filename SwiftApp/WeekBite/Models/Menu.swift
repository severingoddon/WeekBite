import Foundation

struct MenuModel: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let ingredients: [String]
    let note: String
    let effort_min: Int
    let link: String
    let is_own: Bool?
    let owner_name: String?

    init(id: Int, title: String, ingredients: [String], note: String, effort_min: Int, link: String = "", is_own: Bool? = nil, owner_name: String? = nil) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.note = note
        self.effort_min = effort_min
        self.link = link
        self.is_own = is_own
        self.owner_name = owner_name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        ingredients = try container.decode([String].self, forKey: .ingredients)
        note = try container.decode(String.self, forKey: .note)
        effort_min = try container.decode(Int.self, forKey: .effort_min)
        link = try container.decodeIfPresent(String.self, forKey: .link) ?? ""
        is_own = try container.decodeIfPresent(Bool.self, forKey: .is_own)
        owner_name = try container.decodeIfPresent(String.self, forKey: .owner_name)
    }
}

struct MenuCreate: Codable {
    let title: String
    let ingredients: [String]
    let note: String
    let effort_min: Int
    let link: String
}
