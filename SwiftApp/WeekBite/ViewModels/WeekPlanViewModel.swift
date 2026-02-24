import Foundation

@Observable
final class WeekPlanViewModel {
    var currentWeek: Week?
    var nextWeekExists: Bool = false
    var nextWeekStartDate: String = ""
    var noWeekFound: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    var weekLabel: String {
        guard let week = currentWeek, let start = week.start_date.toDate() else { return "" }
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start)!
        return "\(start.formatDayMonth()) – \(end.formatDayMonth())"
    }

    var isCurrentWeek: Bool {
        guard let week = currentWeek else { return false }
        let monday = Date().mondayOfWeek()
        return week.start_date == monday.toISODateString()
    }

    func loadWeek(date: String? = nil) async {
        noWeekFound = false
        isLoading = true
        defer { isLoading = false }

        do {
            currentWeek = try await api.getWeek(date: date)
            await checkNextWeek()
        } catch let error as APIError {
            if case .serverError(let code, _) = error, code == 404 {
                currentWeek = nil
                noWeekFound = true
            } else if case .unauthorized = error {
                // handled by APIClient
            } else {
                errorMessage = "Keine Woche für dieses Datum gefunden"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateWeekDay(_ day: WeekDay, menuId: Int?) {
        guard let week = currentWeek else { return }

        // Optimistic: update locally
        if let idx = week.days.firstIndex(where: { $0.day == day.day }) {
            var updatedDays = week.days
            if menuId == nil {
                updatedDays[idx] = WeekDay(id: day.id, day: day.day, menu: nil)
            }
            currentWeek = Week(id: week.id, start_date: week.start_date, days: updatedDays)
        }

        let startDate = week.start_date
        Task {
            do {
                _ = try await api.updateWeekDay(week.id, day.day, menuId: menuId)
            } catch {}
            await loadWeek(date: startDate)
        }
    }

    func resetWeek() {
        guard let week = currentWeek else { return }

        // Optimistic: clear all menus locally
        let clearedDays = week.days.map { WeekDay(id: $0.id, day: $0.day, menu: nil) }
        currentWeek = Week(id: week.id, start_date: week.start_date, days: clearedDays)

        let startDate = week.start_date
        Task {
            try? await api.resetWeek(week.id)
            await loadWeek(date: startDate)
        }
    }

    func createOrShowNextWeek() -> String? {
        if nextWeekExists {
            Task { await loadWeek(date: nextWeekStartDate) }
            return nil
        } else {
            Task {
                do {
                    let week = try await api.createNextWeek()
                    currentWeek = week
                    noWeekFound = false
                    await checkNextWeek()
                } catch {
                    await checkNextWeek()
                }
            }
            return "Nächste Woche erstellt"
        }
    }

    func goToCurrentWeek() {
        Task { await loadWeek() }
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

    private func checkNextWeek() async {
        do {
            let status = try await api.getNextWeekStatus()
            nextWeekExists = status.exists
            nextWeekStartDate = status.start_date
        } catch {}
    }
}
