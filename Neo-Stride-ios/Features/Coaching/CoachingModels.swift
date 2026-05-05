import Foundation

struct GoalRequest: Encodable, Equatable {
    let userId: Int
    let periodType: String
    let customWeeks: Int?
    let runningDays: [String]
    let goalDistanceKm: Double
    let goalPaceMinPerKm: Double
    let startDate: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case periodType = "period_type"
        case customWeeks = "custom_weeks"
        case runningDays = "running_days"
        case goalDistanceKm = "goal_distance_km"
        case goalPaceMinPerKm = "goal_pace_min_per_km"
        case startDate = "start_date"
    }
}

struct GoalResponse: Decodable, Equatable {
    let goalId: Int?
    let hasActiveGoal: Bool
    let status: String?
    let goal: GoalInfo?
    let planDays: [PlanDayResponse]

    enum CodingKeys: String, CodingKey {
        case goalId = "goal_id"
        case hasActiveGoal = "has_active_goal"
        case status
        case goal
        case planDays = "plan_days"
    }

    init(goalId: Int?, hasActiveGoal: Bool, status: String?, goal: GoalInfo?, planDays: [PlanDayResponse]) {
        self.goalId = goalId
        self.hasActiveGoal = hasActiveGoal
        self.status = status
        self.goal = goal
        self.planDays = planDays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.goalId = try container.decodeIfPresent(Int.self, forKey: .goalId)
        self.hasActiveGoal = try container.decodeIfPresent(Bool.self, forKey: .hasActiveGoal) ?? false
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.goal = try container.decodeIfPresent(GoalInfo.self, forKey: .goal)
        self.planDays = try container.decodeIfPresent([PlanDayResponse].self, forKey: .planDays) ?? []
    }
}

struct GoalInfo: Decodable, Equatable, Identifiable {
    var id: Int { goalId }

    let goalId: Int
    let periodType: String?
    let customWeeks: Int?
    let runningDays: [String]
    let goalDistanceKm: Double?
    let goalPaceMinPerKm: Double?
    let startDate: String?
    let endDate: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case goalId = "goal_id"
        case periodType = "period_type"
        case customWeeks = "custom_weeks"
        case runningDays = "running_days"
        case goalDistanceKm = "goal_distance_km"
        case goalPaceMinPerKm = "goal_pace_min_per_km"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
    }

    init(
        goalId: Int,
        periodType: String? = nil,
        customWeeks: Int? = nil,
        runningDays: [String] = [],
        goalDistanceKm: Double? = nil,
        goalPaceMinPerKm: Double? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        createdAt: String? = nil
    ) {
        self.goalId = goalId
        self.periodType = periodType
        self.customWeeks = customWeeks
        self.runningDays = runningDays
        self.goalDistanceKm = goalDistanceKm
        self.goalPaceMinPerKm = goalPaceMinPerKm
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.goalId = try container.decode(Int.self, forKey: .goalId)
        self.periodType = try container.decodeIfPresent(String.self, forKey: .periodType)
        self.customWeeks = try container.decodeIfPresent(Int.self, forKey: .customWeeks)
        self.runningDays = try container.decodeIfPresent([String].self, forKey: .runningDays) ?? []
        self.goalDistanceKm = try container.decodeIfPresent(Double.self, forKey: .goalDistanceKm)
        self.goalPaceMinPerKm = try container.decodeIfPresent(Double.self, forKey: .goalPaceMinPerKm)
        self.startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        self.endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
}

struct PlanDayResponse: Decodable, Equatable, Identifiable, Hashable {
    var id: Int { planDayId }

    let planDayId: Int
    let planDate: String?
    let dayDistanceKm: Double?
    let dayPaceMinPerKm: Double?
    let description: String?
    let completed: Bool
    let aiFeedbackComment: String?
    let aiFeedbackAt: String?

    enum CodingKeys: String, CodingKey {
        case planDayId = "plan_day_id"
        case planDate = "plan_date"
        case dayDistanceKm = "day_distance_km"
        case dayPaceMinPerKm = "day_pace_min_per_km"
        case description
        case completed = "is_completed"
        case aiFeedbackComment = "ai_feedback_comment"
        case aiFeedbackAt = "ai_feedback_at"
    }

    init(
        planDayId: Int,
        planDate: String? = nil,
        dayDistanceKm: Double? = nil,
        dayPaceMinPerKm: Double? = nil,
        description: String? = nil,
        completed: Bool = false,
        aiFeedbackComment: String? = nil,
        aiFeedbackAt: String? = nil
    ) {
        self.planDayId = planDayId
        self.planDate = planDate
        self.dayDistanceKm = dayDistanceKm
        self.dayPaceMinPerKm = dayPaceMinPerKm
        self.description = description
        self.completed = completed
        self.aiFeedbackComment = aiFeedbackComment
        self.aiFeedbackAt = aiFeedbackAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.planDayId = try container.decode(Int.self, forKey: .planDayId)
        self.planDate = try container.decodeIfPresent(String.self, forKey: .planDate)
        self.dayDistanceKm = try container.decodeIfPresent(Double.self, forKey: .dayDistanceKm)
        self.dayPaceMinPerKm = try container.decodeIfPresent(Double.self, forKey: .dayPaceMinPerKm)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        self.aiFeedbackComment = try container.decodeIfPresent(String.self, forKey: .aiFeedbackComment)
        self.aiFeedbackAt = try container.decodeIfPresent(String.self, forKey: .aiFeedbackAt)
    }
}

struct TodayPlanResponse: Decodable, Equatable {
    let hasPlan: Bool
    let planDay: PlanDayResponse?
    let goal: GoalInfo?

    enum CodingKeys: String, CodingKey {
        case hasPlan = "has_plan"
        case planDay = "plan_day"
        case goal
    }
}

struct FeedbackRequest: Encodable, Equatable {
    let planDayId: Int
    let actualDistanceKm: Double
    let actualTimeSec: Int
    let actualPaceMinPerKm: Double

    enum CodingKeys: String, CodingKey {
        case planDayId = "plan_day_id"
        case actualDistanceKm = "actual_distance_km"
        case actualTimeSec = "actual_time_sec"
        case actualPaceMinPerKm = "actual_pace_min_per_km"
    }
}

struct FeedbackResponse: Decodable, Equatable {
    let planDayId: Int
    let completed: Bool
    let aiFeedbackComment: String?
    let aiFeedbackAt: String?

    enum CodingKeys: String, CodingKey {
        case planDayId = "plan_day_id"
        case completed = "is_completed"
        case aiFeedbackComment = "ai_feedback_comment"
        case aiFeedbackAt = "ai_feedback_at"
    }
}

struct DeleteGoalResponse: Decodable, Equatable {
    let status: String?
    let message: String?
}

struct CoachingGoalSummary: Equatable {
    let goalId: Int
    let periodText: String
    let runningDaysText: String
    let targetText: String
    let dateRangeText: String

    init?(response: GoalResponse) {
        guard response.hasActiveGoal, let goal = response.goal else { return nil }
        self.init(goal: goal)
    }

    init(goal: GoalInfo) {
        self.goalId = goal.goalId
        self.periodText = Self.periodText(periodType: goal.periodType, customWeeks: goal.customWeeks)
        self.runningDaysText = Self.runningDaysText(goal.runningDays)
        self.targetText = Self.targetText(distance: goal.goalDistanceKm, pace: goal.goalPaceMinPerKm)
        self.dateRangeText = Self.dateRangeText(startDate: goal.startDate, endDate: goal.endDate)
    }

    private static func periodText(periodType: String?, customWeeks: Int?) -> String {
        switch periodType {
        case "1_month": return "1개월"
        case "3_months": return "3개월"
        case "6_months": return "6개월"
        case "1_year": return "1년"
        case "custom": return "\(customWeeks ?? 0)주"
        default: return "기간 미정"
        }
    }

    private static func runningDaysText(_ days: [String]) -> String {
        let labels = days.map { day in
            switch day.lowercased() {
            case "sun": return "일"
            case "mon": return "월"
            case "tue": return "화"
            case "wed": return "수"
            case "thu": return "목"
            case "fri": return "금"
            case "sat": return "토"
            default: return day
            }
        }
        return labels.isEmpty ? "요일 미정" : labels.joined(separator: ", ")
    }

    private static func targetText(distance: Double?, pace: Double?) -> String {
        let distanceText = distance.map { String(format: "%.1f km", $0) } ?? "거리 미정"
        let paceText = pace.map { String(format: "%.2f /km", $0) } ?? "페이스 미정"
        return "\(distanceText) · \(paceText)"
    }

    private static func dateRangeText(startDate: String?, endDate: String?) -> String {
        switch (startDate, endDate) {
        case let (start?, end?): return "\(start) ~ \(end)"
        case let (start?, nil): return "\(start) 시작"
        default: return "일정 미정"
        }
    }
}

extension PlanDayResponse {
    var dateText: String { planDate ?? "날짜 미정" }

    var distanceText: String {
        dayDistanceKm.map { String(format: "%.1f km", $0) } ?? "거리 미정"
    }

    var paceText: String {
        dayPaceMinPerKm.map { String(format: "%.2f /km", $0) } ?? "페이스 미정"
    }

    var statusText: String {
        completed ? "완료" : "예정"
    }
}
