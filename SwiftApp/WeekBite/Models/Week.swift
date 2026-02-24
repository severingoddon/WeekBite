import Foundation

struct WeekDay: Codable, Identifiable, Hashable {
    static func == (lhs: WeekDay, rhs: WeekDay) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: Int
    let day: String
    let menu: MenuModel?
}

struct Week: Codable, Identifiable {
    let id: Int
    let start_date: String
    let days: [WeekDay]
}

struct NextWeekStatus: Codable {
    let exists: Bool
    let start_date: String
}
