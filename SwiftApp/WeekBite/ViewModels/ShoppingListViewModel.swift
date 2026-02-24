import Foundation

@Observable
final class ShoppingListViewModel {
    var items: [ShoppingItem] = []
    var newName: String = ""
    var newQuantity: String = ""
    var editingId: Int?
    var editName: String = ""
    var editQuantity: String = ""

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func loadItems() async {
        do {
            items = try await api.getShoppingItems()
        } catch {}
    }

    func addItem() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        let quantity = newQuantity.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        guard !items.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return }

        // Optimistic: add locally with temp ID
        let tempId = -(items.count + 1)
        let tempItem = ShoppingItem(id: tempId, name: name, quantity: quantity, checked: false, created: true)
        items.append(tempItem)
        newName = ""
        newQuantity = ""

        Task {
            do {
                _ = try await api.addShoppingItem(ShoppingItemCreate(name: name, quantity: quantity))
            } catch {}
            await loadItems()
        }
    }

    func startEdit(_ item: ShoppingItem) {
        editingId = item.id
        editName = item.name
        editQuantity = item.quantity
    }

    func cancelEdit() {
        editingId = nil
    }

    func saveEdit(_ id: Int) {
        let name = editName.trimmingCharacters(in: .whitespaces)
        let quantity = editQuantity.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        // Optimistic: update locally
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx] = ShoppingItem(id: id, name: name, quantity: quantity, checked: items[idx].checked, created: items[idx].created)
        }
        editingId = nil

        Task {
            do {
                _ = try await api.updateShoppingItem(id, ShoppingItemCreate(name: name, quantity: quantity))
            } catch {}
            await loadItems()
        }
    }

    func toggleItem(_ item: ShoppingItem) {
        // Optimistic: toggle locally
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = ShoppingItem(id: item.id, name: item.name, quantity: item.quantity, checked: !item.checked, created: item.created)
        }

        Task {
            try? await api.toggleShoppingItem(item.id)
        }
    }

    func deleteItem(_ id: Int) {
        // Optimistic: remove locally
        items.removeAll { $0.id == id }

        Task {
            try? await api.deleteShoppingItem(id)
        }
    }

    func clearList() {
        // Optimistic: clear locally
        items.removeAll()

        Task {
            try? await api.clearShoppingList()
        }
    }
}
