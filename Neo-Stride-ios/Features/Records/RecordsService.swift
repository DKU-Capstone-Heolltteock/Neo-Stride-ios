import Foundation

final class RecordsService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchUserRecords(userId: Int) async throws -> [RunningRecordResponse] {
        try await apiClient.send(APIEndpoint(method: "GET", path: "/api/running/records/user/\(userId)"))
    }

    func fetchMonthlyRecords(year: Int, month: Int) async throws -> [RunningRecordResponse] {
        try await apiClient.send(APIEndpoint(
            method: "GET",
            path: "/api/running/records",
            queryItems: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "month", value: String(month))
            ]
        ))
    }

    func fetchRecordDetail(recordId: Int) async throws -> RunningRecordResponse {
        try await apiClient.send(APIEndpoint(method: "GET", path: "/api/running/records/\(recordId)"))
    }
}
