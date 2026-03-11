import Foundation

@Observable
final class MenuManagementViewModel {
    var menus: [MenuModel] = []
    var editingMenu: MenuModel?

    // Form fields
    var menuTitle: String = ""
    var ingredientInput: String = ""
    var ingredients: [String] = []
    var menuNote: String = ""
    var menuEffort: Int = 20
    var menuLink: String = ""

    var toastMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func loadMenus() async {
        do {
            menus = try await api.getMenus()
        } catch {}
    }

    func addIngredient() {
        let val = ingredientInput.trimmingCharacters(in: .whitespaces)
        if !val.isEmpty && !ingredients.contains(val) {
            ingredients.append(val)
            ingredientInput = ""
        }
    }

    func removeIngredient(_ ingredient: String) {
        ingredients.removeAll { $0 == ingredient }
    }

    func saveMenu() -> String? {
        let title = menuTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }

        let data = MenuCreate(
            title: title,
            ingredients: ingredients,
            note: menuNote,
            effort_min: menuEffort,
            link: menuLink.trimmingCharacters(in: .whitespaces)
        )

        let isEdit = editingMenu != nil
        let editId = editingMenu?.id

        // Optimistic: if editing, update locally
        if let editId, let idx = menus.firstIndex(where: { $0.id == editId }) {
            menus[idx] = MenuModel(id: editId, title: title, ingredients: ingredients, note: menuNote, effort_min: menuEffort, link: menuLink.trimmingCharacters(in: .whitespaces), is_own: menus[idx].is_own, owner_name: menus[idx].owner_name)
        }
        resetForm()

        Task {
            do {
                if let editId {
                    _ = try await api.updateMenu(editId, data)
                } else {
                    _ = try await api.createMenu(data)
                }
            } catch {}
            await loadMenus()
        }
        return isEdit ? "Menu aktualisiert" : "Menu erstellt"
    }

    func editMenu(_ menu: MenuModel) {
        editingMenu = menu
        menuTitle = menu.title
        ingredients = menu.ingredients
        menuNote = menu.note
        menuEffort = menu.effort_min
        menuLink = menu.link
    }

    func deleteMenu(_ menu: MenuModel) -> String? {
        // Optimistic: remove locally
        menus.removeAll { $0.id == menu.id }
        if editingMenu?.id == menu.id {
            resetForm()
        }

        Task {
            try? await api.deleteMenu(menu.id)
            await loadMenus()
        }
        return "Menu gelöscht"
    }

    func resetForm() {
        editingMenu = nil
        menuTitle = ""
        ingredientInput = ""
        ingredients = []
        menuNote = ""
        menuEffort = 20
        menuLink = ""
    }

}
