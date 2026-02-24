import Foundation

struct TourStep: Identifiable {
    let id = UUID()
    let anchorID: String
    let title: String
    let text: String
    let position: TourPosition
}

enum TourPosition {
    case top, bottom, left, right
}
