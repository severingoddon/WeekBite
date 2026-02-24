import Foundation

@Observable
final class APIClient {
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let encoder = JSONEncoder()

    var authManager: AuthManager?

    private func makeURL(_ path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        var components = URLComponents(string: APIEndpoints.baseURL + path)!
        components.queryItems = queryItems
        guard let url = components.url else { throw APIError.invalidURL }
        return url
    }

    private func makeRequest(_ method: String, path: String, body: Data? = nil, queryItems: [URLQueryItem]? = nil) throws -> URLRequest {
        let url = try makeURL(path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authManager?.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 401 {
            await MainActor.run { authManager?.logout() }
            throw APIError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            let detail = try? decoder.decode(APIDetailError.self, from: data)
            throw APIError.serverError(http.statusCode, detail?.detail)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func performVoid(_ request: URLRequest) async throws {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 401 {
            await MainActor.run { authManager?.logout() }
            throw APIError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            let detail = try? decoder.decode(APIDetailError.self, from: data)
            throw APIError.serverError(http.statusCode, detail?.detail)
        }
    }

    // MARK: - Auth

    func getMe() async throws -> UserInfo {
        let request = try makeRequest("GET", path: APIEndpoints.me)
        return try await perform(request)
    }

    // MARK: - Menus

    func getMenus() async throws -> [MenuModel] {
        let request = try makeRequest("GET", path: APIEndpoints.menus)
        return try await perform(request)
    }

    func createMenu(_ menu: MenuCreate) async throws -> MenuModel {
        let body = try encoder.encode(menu)
        let request = try makeRequest("POST", path: APIEndpoints.menus, body: body)
        return try await perform(request)
    }

    func updateMenu(_ id: Int, _ menu: MenuCreate) async throws -> MenuModel {
        let body = try encoder.encode(menu)
        let request = try makeRequest("PUT", path: APIEndpoints.menu(id), body: body)
        return try await perform(request)
    }

    func deleteMenu(_ id: Int) async throws {
        let request = try makeRequest("DELETE", path: APIEndpoints.menu(id))
        try await performVoid(request)
    }

    // MARK: - Week

    func getWeek(date: String? = nil) async throws -> Week {
        var queryItems: [URLQueryItem]? = nil
        if let date {
            queryItems = [URLQueryItem(name: "date_param", value: date)]
        }
        let request = try makeRequest("GET", path: APIEndpoints.week, queryItems: queryItems)
        return try await perform(request)
    }

    func updateWeekDay(_ weekId: Int, _ day: String, menuId: Int?) async throws -> WeekDay {
        let body = try encoder.encode(["menu_id": menuId])
        let request = try makeRequest("PUT", path: APIEndpoints.weekDay(weekId, day), body: body)
        return try await perform(request)
    }

    func resetWeek(_ weekId: Int) async throws {
        let request = try makeRequest("DELETE", path: APIEndpoints.resetWeek(weekId))
        try await performVoid(request)
    }

    func getNextWeekStatus() async throws -> NextWeekStatus {
        let request = try makeRequest("GET", path: APIEndpoints.nextWeekExists)
        return try await perform(request)
    }

    func createNextWeek() async throws -> Week {
        let request = try makeRequest("POST", path: APIEndpoints.nextWeek, body: try encoder.encode([String: String]()))
        return try await perform(request)
    }

    // MARK: - Shopping

    func getShoppingItems() async throws -> [ShoppingItem] {
        let request = try makeRequest("GET", path: APIEndpoints.shopping)
        return try await perform(request)
    }

    func addShoppingItem(_ item: ShoppingItemCreate) async throws -> ShoppingItem {
        let body = try encoder.encode(item)
        let request = try makeRequest("POST", path: APIEndpoints.shopping, body: body)
        return try await perform(request)
    }

    func updateShoppingItem(_ id: Int, _ item: ShoppingItemCreate) async throws -> ShoppingItem {
        let body = try encoder.encode(item)
        let request = try makeRequest("PUT", path: APIEndpoints.shoppingItem(id), body: body)
        return try await perform(request)
    }

    func toggleShoppingItem(_ id: Int) async throws -> ShoppingItem {
        let request = try makeRequest("PATCH", path: APIEndpoints.toggleShopping(id), body: try encoder.encode([String: String]()))
        return try await perform(request)
    }

    func deleteShoppingItem(_ id: Int) async throws {
        let request = try makeRequest("DELETE", path: APIEndpoints.shoppingItem(id))
        try await performVoid(request)
    }

    func clearShoppingList() async throws {
        let request = try makeRequest("DELETE", path: APIEndpoints.shopping)
        try await performVoid(request)
    }

    // MARK: - Families

    func getFamilies() async throws -> [Family] {
        let request = try makeRequest("GET", path: APIEndpoints.families)
        return try await perform(request)
    }

    func createFamily(_ family: FamilyCreate) async throws -> Family {
        let body = try encoder.encode(family)
        let request = try makeRequest("POST", path: APIEndpoints.families, body: body)
        return try await perform(request)
    }

    func updateFamily(_ id: Int, _ family: FamilyCreate) async throws -> Family {
        let body = try encoder.encode(family)
        let request = try makeRequest("PUT", path: APIEndpoints.family(id), body: body)
        return try await perform(request)
    }

    func deleteFamily(_ id: Int) async throws {
        let request = try makeRequest("DELETE", path: APIEndpoints.family(id))
        try await performVoid(request)
    }

    func inviteToFamily(_ familyId: Int, email: String) async throws -> APIDetailResponse {
        let body = try encoder.encode(["email": email])
        let request = try makeRequest("POST", path: APIEndpoints.invite(familyId), body: body)
        return try await perform(request)
    }

    func removeFamilyMember(_ familyId: Int, userId: Int) async throws {
        let request = try makeRequest("DELETE", path: APIEndpoints.removeMember(familyId, userId))
        try await performVoid(request)
    }

    func acceptInvite(_ inviteId: Int) async throws {
        let request = try makeRequest("POST", path: APIEndpoints.acceptInvite(inviteId), body: try encoder.encode([String: String]()))
        try await performVoid(request)
    }

    func declineInvite(_ inviteId: Int) async throws {
        let request = try makeRequest("POST", path: APIEndpoints.declineInvite(inviteId), body: try encoder.encode([String: String]()))
        try await performVoid(request)
    }

    // MARK: - Context

    func switchContext(familyId: Int?) async throws {
        let body = try encoder.encode(["family_id": familyId])
        let request = try makeRequest("PUT", path: APIEndpoints.context, body: body)
        try await performVoid(request)
    }
}

struct APIDetailResponse: Codable {
    let detail: String?
}
