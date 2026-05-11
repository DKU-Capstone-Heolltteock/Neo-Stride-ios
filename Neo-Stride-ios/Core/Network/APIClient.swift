import Foundation

struct EmptyResponse: Decodable {}

final class APIClient {
    private let config: AppConfig
    private let authStore: AuthStore
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(config: AppConfig, authStore: AuthStore, session: URLSession = .shared) {
        self.config = config
        self.authStore = authStore
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func send<Response: Decodable>(_ endpoint: APIEndpoint) async throws -> Response {
        let request = try makeRequest(endpoint: endpoint, body: Optional<Data>.none)
        return try await perform(request)
    }

    func send<Request: Encodable, Response: Decodable>(_ endpoint: APIEndpoint, body: Request) async throws -> Response {
        let data = try encoder.encode(body)
        let request = try makeRequest(endpoint: endpoint, body: data)
        return try await perform(request)
    }

    func sendMultipart<Response: Decodable>(
        _ endpoint: APIEndpoint,
        fieldName: String,
        fileName: String,
        mimeType: String,
        data: Data
    ) async throws -> Response {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n")

        var request = try makeRequest(endpoint: endpoint, body: body)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    private func makeRequest(endpoint: APIEndpoint, body: Data?) throws -> URLRequest {
        var request = URLRequest(url: try endpoint.url(relativeTo: config.baseURL))
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = authStore.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.missingResponse
            }

            switch httpResponse.statusCode {
            case 200..<300:
                if data.isEmpty, Response.self == EmptyResponse.self {
                    return EmptyResponse() as! Response
                }
                do {
                    return try decoder.decode(Response.self, from: data)
                } catch {
                    throw APIError.decoding(error.localizedDescription)
                }
            case 401:
                throw APIError.unauthorized
            default:
                throw APIError.serverError(
                    statusCode: httpResponse.statusCode,
                    body: String(data: data, encoding: .utf8)
                )
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(error.localizedDescription)
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
