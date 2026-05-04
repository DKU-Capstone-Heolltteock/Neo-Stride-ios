import Foundation

final class AuthService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        try await apiClient.send(
            APIEndpoint(method: "POST", path: "/api/auth/login"),
            body: LoginRequest(email: email, password: password)
        )
    }

    func signup(email: String, name: String, password: String) async throws -> SignupResponse {
        try await apiClient.send(
            APIEndpoint(method: "POST", path: "/api/auth/signup"),
            body: SignupRequest(email: email, name: name, password: password)
        )
    }
}
