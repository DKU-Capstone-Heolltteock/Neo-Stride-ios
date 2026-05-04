import Foundation

final class RunningService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func saveRunningRecord(_ request: RunningRecordRequest) async throws -> RunningRecordResponse {
        try await apiClient.send(
            APIEndpoint(method: "POST", path: "/api/running/records"),
            body: request
        )
    }
}
