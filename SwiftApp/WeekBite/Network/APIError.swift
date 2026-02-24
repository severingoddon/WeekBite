import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(Int, String?)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .unauthorized:
            return "Nicht autorisiert"
        case .serverError(let code, let detail):
            return detail ?? "Serverfehler (\(code))"
        case .decodingError(let error):
            return "Datenverarbeitung fehlgeschlagen: \(error.localizedDescription)"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

struct APIDetailError: Codable {
    let detail: String?
}
