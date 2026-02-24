import Foundation

@Observable
final class MenuPopupViewModel {
    var menus: [MenuModel] = []
    var filteredMenus: [MenuModel] = []
    var searchQuery: String = "" {
        didSet { filterMenus() }
    }
    var expandedMenuId: Int?
    var sortByEffort: Bool = false
    var showNoMenusHint: Bool = false

    private let api: APIClient
    private let tourManager: TourManager

    init(api: APIClient, tourManager: TourManager) {
        self.api = api
        self.tourManager = tourManager
    }

    func loadMenus() async {
        do {
            menus = try await api.getMenus()
            filteredMenus = menus
            if menus.isEmpty && !tourManager.hasSeenTour("no-menus-hint") {
                showNoMenusHint = true
            }
        } catch {}
    }

    func filterMenus() {
        let q = searchQuery.lowercased()
        var result = menus.filter { q.isEmpty || $0.title.lowercased().contains(q) }
        if sortByEffort {
            result.sort { $0.effort_min < $1.effort_min }
        }
        filteredMenus = result
    }

    func toggleSort() {
        sortByEffort.toggle()
        filterMenus()
    }

    func toggleDetails(_ menuId: Int) {
        expandedMenuId = expandedMenuId == menuId ? nil : menuId
    }

    func addToShoppingList(_ ingredient: String) async -> (success: Bool, itemId: Int?) {
        do {
            let item = try await api.addShoppingItem(ShoppingItemCreate(name: ingredient, quantity: ""))
            if item.created == true {
                return (true, item.id)
            }
            return (false, nil)
        } catch {
            return (false, nil)
        }
    }

    func undoShoppingAdd(_ itemId: Int) async {
        try? await api.deleteShoppingItem(itemId)
    }

    func dismissHint() {
        showNoMenusHint = false
        tourManager.markSeen("no-menus-hint")
    }
}
