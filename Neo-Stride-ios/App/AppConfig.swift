import Foundation

struct AppConfig: Equatable {
    let baseURL: URL

    static let `default`: AppConfig = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           let config = try? AppConfig(baseURLString: value) {
            return config
        }

        return try! AppConfig(baseURLString: "http://localhost:8080/")
    }()

    init(baseURLString: String) throws {
        let normalized = baseURLString.hasSuffix("/") ? baseURLString : baseURLString + "/"
        guard let url = URL(string: normalized), url.scheme != nil, url.host != nil else {
            throw AppConfigError.invalidBaseURL(baseURLString)
        }
        self.baseURL = url
    }
}

enum AppConfigError: LocalizedError, Equatable {
    case invalidBaseURL(String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL(let value):
            return "Invalid API base URL: \(value)"
        }
    }
}
