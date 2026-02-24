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

    func saveMenu() async -> String? {
        let title = menuTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }

        let data = MenuCreate(
            title: title,
            ingredients: ingredients,
            note: menuNote,
            effort_min: menuEffort
        )

        do {
            if let editing = editingMenu {
                _ = try await api.updateMenu(editing.id, data)
                resetForm()
                await loadMenus()
                return "Menu aktualisiert"
            } else {
                _ = try await api.createMenu(data)
                resetForm()
                await loadMenus()
                return "Menu erstellt"
            }
        } catch let error as APIError {
            return error.errorDescription
        } catch {
            return "Fehler"
        }
    }

    func editMenu(_ menu: MenuModel) {
        editingMenu = menu
        menuTitle = menu.title
        ingredients = menu.ingredients
        menuNote = menu.note
        menuEffort = menu.effort_min
    }

    func deleteMenu(_ menu: MenuModel) async -> String? {
        do {
            try await api.deleteMenu(menu.id)
            if editingMenu?.id == menu.id {
                resetForm()
            }
            await loadMenus()
            return "Menu gelöscht"
        } catch {
            return "Fehler beim Löschen"
        }
    }

    func resetForm() {
        editingMenu = nil
        menuTitle = ""
        ingredientInput = ""
        ingredients = []
        menuNote = ""
        menuEffort = 20
    }

    // MARK: - CSV Import

    func importCSV(from text: String) async -> String {
        let cleaned = text.replacingOccurrences(of: "\u{FEFF}", with: "")
        let lines = cleaned.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard lines.count >= 2 else { return csvErrorMessage() }

        let header = lines[0].trimmingCharacters(in: .whitespaces)
        let validHeaders = ["Menu;Zutaten", "Menu;Zutaten;Notiz;Aufwand"]
        guard validHeaders.contains(header) else { return csvErrorMessage() }
        let hasExtended = header == "Menu;Zutaten;Notiz;Aufwand"

        var parsed: [MenuCreate] = []
        for i in 1..<lines.count {
            let row = parseCsvRow(lines[i])
            guard row.count >= 2 else { return csvErrorMessage(line: i + 1) }
            let title = row[0].trimmingCharacters(in: .whitespaces)
            let ingredients = row[1].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            let note = hasExtended && row.count > 2 ? row[2].trimmingCharacters(in: .whitespaces) : ""
            let effort = hasExtended && row.count > 3 ? Int(row[3].trimmingCharacters(in: .whitespaces)) ?? 20 : 20
            guard !title.isEmpty else { return csvErrorMessage(line: i + 1) }
            parsed.append(MenuCreate(title: title, ingredients: ingredients, note: note, effort_min: effort))
        }

        var successCount = 0
        for item in parsed {
            do {
                _ = try await api.createMenu(item)
                successCount += 1
            } catch {}
        }

        await loadMenus()
        return "\(successCount) Menus importiert"
    }

    func exportCSV() -> String {
        let header = "Menu;Zutaten;Notiz;Aufwand"
        let rows = menus.map { m in
            let title = m.title.replacingOccurrences(of: "\"", with: "\"\"")
            let ingredients = m.ingredients.joined(separator: ", ").replacingOccurrences(of: "\"", with: "\"\"")
            let note = m.note.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(title)\";\"\(ingredients)\";\"\(note)\";\(m.effort_min)"
        }
        return "\u{FEFF}" + ([header] + rows).joined(separator: "\n")
    }

    private func parseCsvRow(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false

        for (i, char) in line.enumerated() {
            if inQuotes {
                if char == "\"" {
                    let nextIndex = line.index(line.startIndex, offsetBy: i + 1, limitedBy: line.endIndex)
                    if let next = nextIndex, next < line.endIndex && line[next] == "\"" {
                        current += "\""
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == ";" {
                    result.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
            }
        }
        result.append(current)
        return result
    }

    private func csvErrorMessage(line: Int? = nil) -> String {
        if let line {
            return "CSV-Fehler in Zeile \(line). Format: Menu;Zutaten;Notiz;Aufwand"
        }
        return "Ungültiges CSV-Format. Erste Zeile muss \"Menu;Zutaten\" oder \"Menu;Zutaten;Notiz;Aufwand\" sein"
    }
}
