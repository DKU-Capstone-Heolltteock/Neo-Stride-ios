import Foundation

struct APIEndpoint {
    let method: String
    let path: String
    let queryItems: [URLQueryItem]

    init(method: String, path: String, queryItems: [URLQueryItem] = []) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
    }

    func url(relativeTo baseURL: URL) throws -> URL {
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let endpointURL = baseURL.appendingPathComponent(cleanPath)
        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidURL(endpointURL.absoluteString)
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else {
            throw APIError.invalidURL(endpointURL.absoluteString)
        }
        return url
    }
}
