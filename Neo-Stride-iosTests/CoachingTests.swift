import Foundation
import Testing
@testable import Neo_Stride_ios

struct CoachingTests {
    @Test func goalRequestEncodesBackendSnakeCaseFields() throws {
        let request = GoalRequest(
            userId: 3,
            periodType: "3_months",
            customWeeks: nil,
            runningDays: ["mon", "wed", "fri"],
            goalDistanceKm: 10,
            goalPaceMinPerKm: 6.5,
            startDate: "2026-05-05"
        )

        let data = try JSONEncoder().encode(request)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["user_id"] as? Int == 3)
        #expect(object["period_type"] as? String == "3_months")
        #expect(object["running_days"] as? [String] == ["mon", "wed", "fri"])
        #expect(object["goal_distance_km"] as? Double == 10)
        #expect(object["goal_pace_min_per_km"] as? Double == 6.5)
        #expect(object["start_date"] as? String == "2026-05-05")
    }

    @Test func activeGoalResponseDecodesPlanDaysAndDisplayModel() throws {
        let json = """
        {
          "goal_id": 21,
          "has_active_goal": true,
          "status": "active",
          "goal": {
            "goal_id": 21,
            "period_type": "3_months",
            "custom_weeks": null,
            "running_days": ["mon", "wed", "fri"],
            "goal_distance_km": 10.0,
            "goal_pace_min_per_km": 6.5,
            "start_date": "2026-05-05",
            "end_date": "2026-08-05",
            "created_at": "2026-05-05T10:00:00"
          },
          "plan_days": [
            {
              "plan_day_id": 100,
              "plan_date": "2026-05-06",
              "day_distance_km": 3.5,
              "day_pace_min_per_km": 7.0,
              "description": "가볍게 조깅",
              "is_completed": false,
              "ai_feedback_comment": null,
              "ai_feedback_at": null
            }
          ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(GoalResponse.self, from: json)
        let summary = CoachingGoalSummary(response: response)

        #expect(response.goalId == 21)
        #expect(response.hasActiveGoal)
        #expect(response.planDays.count == 1)
        #expect(response.planDays[0].planDayId == 100)
        #expect(summary?.targetText == "10.0 km · 6.50 /km")
        #expect(summary?.runningDaysText == "월, 수, 금")
    }

    @Test func emptyActiveGoalResponseDefaultsMissingPlanDaysToEmptyArray() throws {
        let json = """
        {
          "has_active_goal": false
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(GoalResponse.self, from: json)

        #expect(!response.hasActiveGoal)
        #expect(response.planDays.isEmpty)
        #expect(CoachingGoalSummary(response: response) == nil)
    }

    @Test func todayPlanResponseDecodesNestedGoalAndPlan() throws {
        let json = """
        {
          "has_plan": true,
          "plan_day": {
            "plan_day_id": 200,
            "plan_date": "2026-05-05",
            "day_distance_km": 5.0,
            "day_pace_min_per_km": 6.0,
            "description": "템포런",
            "is_completed": true,
            "ai_feedback_comment": "좋은 페이스입니다.",
            "ai_feedback_at": "2026-05-05T12:00:00"
          },
          "goal": {
            "goal_id": 21,
            "period_type": "1_month",
            "running_days": ["tue"],
            "goal_distance_km": 5.0,
            "goal_pace_min_per_km": 6.0,
            "start_date": "2026-05-01",
            "end_date": "2026-06-01"
          }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(TodayPlanResponse.self, from: json)

        #expect(response.hasPlan)
        #expect(response.planDay?.planDayId == 200)
        #expect(response.planDay?.completed == true)
        #expect(response.goal?.goalId == 21)
    }

    @Test func feedbackRequestAndResponseMatchBackendContract() throws {
        let request = FeedbackRequest(
            planDayId: 200,
            actualDistanceKm: 5.12,
            actualTimeSec: 1800,
            actualPaceMinPerKm: 5.86
        )
        let data = try JSONEncoder().encode(request)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["plan_day_id"] as? Int == 200)
        #expect(object["actual_distance_km"] as? Double == 5.12)
        #expect(object["actual_time_sec"] as? Int == 1800)
        #expect(object["actual_pace_min_per_km"] as? Double == 5.86)

        let responseJson = """
        {
          "plan_day_id": 200,
          "is_completed": true,
          "ai_feedback_comment": "목표 페이스를 달성했습니다.",
          "ai_feedback_at": "2026-05-05T12:00:00"
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(FeedbackResponse.self, from: responseJson)

        #expect(response.planDayId == 200)
        #expect(response.completed)
        #expect(response.aiFeedbackComment == "목표 페이스를 달성했습니다.")
    }

    @MainActor @Test func viewModelLoadMapsActiveGoalAndTodayPlan() async throws {
        let service = MockCoachingService()
        service.activeGoal = GoalResponse(
            goalId: 21,
            hasActiveGoal: true,
            status: "active",
            goal: GoalInfo(
                goalId: 21,
                periodType: "1_month",
                runningDays: ["tue", "thu"],
                goalDistanceKm: 5,
                goalPaceMinPerKm: 6,
                startDate: "2026-05-01",
                endDate: "2026-06-01"
            ),
            planDays: [PlanDayResponse(planDayId: 1, planDate: "2026-05-02")]
        )
        service.todayPlan = TodayPlanResponse(
            hasPlan: true,
            planDay: PlanDayResponse(planDayId: 1, planDate: "2026-05-02"),
            goal: GoalInfo(goalId: 21)
        )
        let authStore = InMemoryAuthStore()
        authStore.save(session: AuthSession(accessToken: "a", refreshToken: "r", userId: 7, nickname: "runner"))
        let viewModel = CoachingViewModel(coachingService: service, authStore: authStore)

        await viewModel.load()

        #expect(viewModel.goalSummary?.goalId == 21)
        #expect(viewModel.goalSummary?.runningDaysText == "화, 목")
        #expect(viewModel.todayPlan?.planDay?.planDayId == 1)
        #expect(viewModel.planDays.count == 1)
    }

    @MainActor @Test func viewModelCreateGoalRequiresAtLeastOneRunningDay() async throws {
        let service = MockCoachingService()
        let authStore = InMemoryAuthStore()
        authStore.save(session: AuthSession(accessToken: "a", refreshToken: "r", userId: 7, nickname: "runner"))
        let viewModel = CoachingViewModel(coachingService: service, authStore: authStore)
        viewModel.selectedDays = []

        await viewModel.createGoal()

        #expect(viewModel.errorMessage == "러닝 요일을 하나 이상 선택해주세요.")
        #expect(service.createdGoalRequest == nil)
    }
}

private final class MockCoachingService: CoachingServicing {
    var activeGoal = GoalResponse(goalId: nil, hasActiveGoal: false, status: nil, goal: nil, planDays: [])
    var todayPlan = TodayPlanResponse(hasPlan: false, planDay: nil, goal: nil)
    var createdGoalRequest: GoalRequest?

    func fetchActiveGoal(userId: Int) async throws -> GoalResponse {
        activeGoal
    }

    func fetchTodayPlan(userId: Int) async throws -> TodayPlanResponse {
        todayPlan
    }

    func createGoal(_ request: GoalRequest) async throws -> GoalResponse {
        createdGoalRequest = request
        return activeGoal
    }

    func requestFeedback(planDayId: Int, request: FeedbackRequest) async throws -> FeedbackResponse {
        FeedbackResponse(planDayId: planDayId, completed: true, aiFeedbackComment: "ok", aiFeedbackAt: nil)
    }

    func deleteGoal(goalId: Int) async throws -> DeleteGoalResponse {
        DeleteGoalResponse(status: "success", message: nil)
    }
}
