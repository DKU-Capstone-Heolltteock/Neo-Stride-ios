import Foundation

protocol CoachingServicing {
    func fetchActiveGoal(userId: Int) async throws -> GoalResponse
    func fetchTodayPlan(userId: Int) async throws -> TodayPlanResponse
    func createGoal(_ request: GoalRequest) async throws -> GoalResponse
    func requestFeedback(planDayId: Int, request: FeedbackRequest) async throws -> FeedbackResponse
    func deleteGoal(goalId: Int) async throws -> DeleteGoalResponse
}

final class CoachingService: CoachingServicing {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func fetchActiveGoal(userId: Int) async throws -> GoalResponse {
        try await apiClient.send(APIEndpoint(
            method: "GET",
            path: "/api/coaching/goals/active",
            queryItems: [URLQueryItem(name: "user_id", value: String(userId))]
        ))
    }

    func fetchTodayPlan(userId: Int) async throws -> TodayPlanResponse {
        try await apiClient.send(APIEndpoint(
            method: "GET",
            path: "/api/coaching/plans/today",
            queryItems: [URLQueryItem(name: "user_id", value: String(userId))]
        ))
    }

    func createGoal(_ request: GoalRequest) async throws -> GoalResponse {
        try await apiClient.send(APIEndpoint(method: "POST", path: "/api/coaching/goals"), body: request)
    }

    func requestFeedback(planDayId: Int, request: FeedbackRequest) async throws -> FeedbackResponse {
        try await apiClient.send(
            APIEndpoint(method: "POST", path: "/api/coaching/plans/\(planDayId)/feedback"),
            body: request
        )
    }

    func deleteGoal(goalId: Int) async throws -> DeleteGoalResponse {
        try await apiClient.send(APIEndpoint(method: "DELETE", path: "/api/coaching/goals/\(goalId)"))
    }
}
