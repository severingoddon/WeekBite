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

    func updateWeekDay(_ day: WeekDay, menuId: Int?) async {
        guard let week = currentWeek else { return }
        do {
            _ = try await api.updateWeekDay(week.id, day.day, menuId: menuId)
            await loadWeek(date: week.start_date)
        } catch {}
    }

    func resetWeek() async {
        guard let week = currentWeek else { return }
        do {
            try await api.resetWeek(week.id)
            await loadWeek(date: week.start_date)
        } catch {}
    }

    func createOrShowNextWeek() async -> String? {
        if nextWeekExists {
            await loadWeek(date: nextWeekStartDate)
            return nil
        } else {
            do {
                let week = try await api.createNextWeek()
                currentWeek = week
                noWeekFound = false
                await checkNextWeek()
                return "Nächste Woche erstellt"
            } catch {
                await checkNextWeek()
                return "Nächste Woche existiert bereits"
            }
        }
    }

    func goToCurrentWeek() async {
        await loadWeek()
    }

    private func checkNextWeek() async {
        do {
            let status = try await api.getNextWeekStatus()
            nextWeekExists = status.exists
            nextWeekStartDate = status.start_date
        } catch {}
    }
}
