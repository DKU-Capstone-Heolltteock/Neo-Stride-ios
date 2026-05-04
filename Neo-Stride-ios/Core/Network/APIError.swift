import Foundation

enum APIError: Error, LocalizedError, Equatable {
    case invalidURL(String)
    case unauthorized
    case serverError(statusCode: Int, body: String?)
    case decoding(String)
    case network(String)
    case missingResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            return "Invalid URL: \(value)"
        case .unauthorized:
            return "Authentication is required."
        case .serverError(let statusCode, let body):
            return "Server error \(statusCode): \(body ?? "")"
        case .decoding(let message):
            return "Failed to decode response: \(message)"
        case .network(let message):
            return "Network error: \(message)"
        case .missingResponse:
            return "Missing HTTP response."
        }
    }
}
