import Combine
import Foundation

@MainActor
final class CoachingViewModel: ObservableObject {
    @Published private(set) var activeGoal: GoalResponse?
    @Published private(set) var goalSummary: CoachingGoalSummary?
    @Published private(set) var todayPlan: TodayPlanResponse?
    @Published private(set) var planDays: [PlanDayResponse] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let periodOptions: [GoalPeriodOption] = GoalPeriodOption.defaults
    let dayOptions: [RunningDayOption] = RunningDayOption.defaults

    @Published var selectedPeriod: GoalPeriodOption = GoalPeriodOption.defaults[1]
    @Published var customWeeksText = "8"
    @Published var selectedDays: Set<String> = ["mon", "wed", "fri"]
    @Published var selectedDistanceKm: Double = 5
    @Published var selectedPaceMinutes: Int = 6
    @Published var selectedPaceSeconds: Int = 30
    @Published var startDate: Date = Date()

    private let coachingService: CoachingServicing
    private let authStore: AuthStore

    init(coachingService: CoachingServicing, authStore: AuthStore) {
        self.coachingService = coachingService
        self.authStore = authStore
    }

    func load() async {
        guard let userId = authStore.userId else {
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let goal = try await coachingService.fetchActiveGoal(userId: userId)
            let today = try await coachingService.fetchTodayPlan(userId: userId)
            apply(goalResponse: goal)
            todayPlan = today
        } catch {
            errorMessage = "코칭 정보를 불러오지 못했습니다."
        }
    }

    func createGoal() async {
        guard let userId = authStore.userId else {
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }
        guard !selectedDays.isEmpty else {
            errorMessage = "러닝 요일을 하나 이상 선택해주세요."
            return
        }
        guard selectedPeriod.periodType != "custom" || parsedCustomWeeks != nil else {
            errorMessage = "커스텀 기간을 주 단위 숫자로 입력해주세요."
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            let request = GoalRequest(
                userId: userId,
                periodType: selectedPeriod.periodType,
                customWeeks: selectedPeriod.periodType == "custom" ? parsedCustomWeeks : nil,
                runningDays: orderedSelectedDays,
                goalDistanceKm: selectedDistanceKm,
                goalPaceMinPerKm: selectedPace,
                startDate: Self.dateFormatter.string(from: startDate)
            )
            let response = try await coachingService.createGoal(request)
            apply(goalResponse: response)
            todayPlan = try? await coachingService.fetchTodayPlan(userId: userId)
            successMessage = "코칭 목표를 생성했습니다."
        } catch {
            errorMessage = "코칭 목표를 생성하지 못했습니다."
        }
    }

    func deleteActiveGoal() async {
        guard let goalId = activeGoal?.goalId ?? activeGoal?.goal?.goalId else {
            errorMessage = "삭제할 코칭 목표가 없습니다."
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil
        defer { isSaving = false }

        do {
            _ = try await coachingService.deleteGoal(goalId: goalId)
            activeGoal = nil
            goalSummary = nil
            todayPlan = nil
            planDays = []
            successMessage = "코칭 목표를 삭제했습니다."
        } catch {
            errorMessage = "코칭 목표를 삭제하지 못했습니다."
        }
    }

    func toggleDay(_ dayValue: String) {
        if selectedDays.contains(dayValue) {
            selectedDays.remove(dayValue)
        } else {
            selectedDays.insert(dayValue)
        }
    }

    private func apply(goalResponse: GoalResponse) {
        activeGoal = goalResponse
        goalSummary = CoachingGoalSummary(response: goalResponse)
        planDays = goalResponse.planDays.sorted { ($0.planDate ?? "") < ($1.planDate ?? "") }
    }

    private var parsedCustomWeeks: Int? {
        guard let weeks = Int(customWeeksText.trimmingCharacters(in: .whitespacesAndNewlines)), weeks > 0 else {
            return nil
        }
        return weeks
    }

    private var selectedPace: Double {
        Double(selectedPaceMinutes) + Double(selectedPaceSeconds) / 60.0
    }

    private var orderedSelectedDays: [String] {
        dayOptions.map(\.value).filter { selectedDays.contains($0) }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct GoalPeriodOption: Identifiable, Hashable {
    let id: String
    let title: String
    let periodType: String

    static let defaults: [GoalPeriodOption] = [
        GoalPeriodOption(id: "1_month", title: "1개월", periodType: "1_month"),
        GoalPeriodOption(id: "3_months", title: "3개월", periodType: "3_months"),
        GoalPeriodOption(id: "6_months", title: "6개월", periodType: "6_months"),
        GoalPeriodOption(id: "1_year", title: "1년", periodType: "1_year"),
        GoalPeriodOption(id: "custom", title: "직접 입력", periodType: "custom")
    ]
}

struct RunningDayOption: Identifiable, Hashable {
    let id: String
    let value: String
    let title: String

    static let defaults: [RunningDayOption] = [
        RunningDayOption(id: "sun", value: "sun", title: "일"),
        RunningDayOption(id: "mon", value: "mon", title: "월"),
        RunningDayOption(id: "tue", value: "tue", title: "화"),
        RunningDayOption(id: "wed", value: "wed", title: "수"),
        RunningDayOption(id: "thu", value: "thu", title: "목"),
        RunningDayOption(id: "fri", value: "fri", title: "금"),
        RunningDayOption(id: "sat", value: "sat", title: "토")
    ]
}
