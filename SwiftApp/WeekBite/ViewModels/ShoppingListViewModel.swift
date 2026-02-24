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

    func addItem() async -> Bool {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return false }
        guard !items.contains(where: { $0.name.lowercased() == name.lowercased() }) else { return false }

        do {
            _ = try await api.addShoppingItem(ShoppingItemCreate(name: name, quantity: newQuantity.trimmingCharacters(in: .whitespaces)))
            newName = ""
            newQuantity = ""
            await loadItems()
            return true
        } catch {
            return false
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

    func saveEdit(_ id: Int) async {
        let name = editName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        do {
            _ = try await api.updateShoppingItem(id, ShoppingItemCreate(name: name, quantity: editQuantity.trimmingCharacters(in: .whitespaces)))
            editingId = nil
            await loadItems()
        } catch {}
    }

    func toggleItem(_ item: ShoppingItem) async {
        do {
            let updated = try await api.toggleShoppingItem(item.id)
            if let idx = items.firstIndex(where: { $0.id == item.id }) {
                items[idx] = updated
            }
        } catch {}
    }

    func deleteItem(_ id: Int) async {
        do {
            try await api.deleteShoppingItem(id)
            await loadItems()
        } catch {}
    }

    func clearList() async {
        do {
            try await api.clearShoppingList()
            await loadItems()
        } catch {}
    }
}
