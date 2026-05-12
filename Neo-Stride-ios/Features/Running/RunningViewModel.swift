import Combine
import Foundation

@MainActor
final class RunningViewModel: ObservableObject {
    enum State: Equatable {
        case ready
        case running
        case paused
        case result
        case saving
    }

    @Published private(set) var state: State = .ready
    @Published private(set) var summary = RunningSummary(distanceKilometers: 0, durationSeconds: 0, paceMinutesPerKilometer: 0, calories: 0, route: [])
    @Published var errorMessage: String?
    @Published private(set) var savedRecordId: Int?
    @Published private(set) var didSaveRecord = false
    @Published private(set) var pendingWatchSummaries: [WatchWorkoutPendingSummary] = []
    @Published private(set) var savingWatchSummaryId: WatchWorkoutPendingSummary.ID?

    private let runningService: RunningService
    private let authStore: AuthStore
    private let watchWorkoutStore: WatchWorkoutStore
    private var calculator = RunningMetricsCalculator()
    private var timer: Timer?

    init(
        runningService: RunningService,
        authStore: AuthStore,
        watchWorkoutStore: WatchWorkoutStore = .shared
    ) {
        self.runningService = runningService
        self.authStore = authStore
        self.watchWorkoutStore = watchWorkoutStore
        do {
            self.pendingWatchSummaries = try watchWorkoutStore.pendingSummaries()
        } catch {
            self.pendingWatchSummaries = []
            self.errorMessage = Self.userFacingMessage(for: error)
        }
    }

    func start() {
        calculator.start()
        summary = calculator.summary()
        errorMessage = nil
        savedRecordId = nil
        didSaveRecord = false
        state = .running
        startTimer()
    }

    func add(sample: RunningLocationSample) {
        guard state == .running else { return }
        calculator.add(sample: sample)
        summary = calculator.summary()
    }

    func pause() {
        guard state == .running else { return }
        calculator.pause()
        state = .paused
        refreshSummary()
    }

    func resume() {
        guard state == .paused else { return }
        calculator.resume()
        state = .running
        refreshSummary()
    }

    func stop() {
        guard state == .running || state == .paused else { return }
        timer?.invalidate()
        timer = nil
        summary = calculator.summary()
        state = .result
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        calculator.reset()
        summary = calculator.summary()
        savedRecordId = nil
        didSaveRecord = false
        errorMessage = nil
        state = .ready
    }

    func save() async {
        guard state == .result else { return }
        guard let userId = authStore.userId else {
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }
        guard !summary.route.isEmpty else {
            errorMessage = "저장할 위치 기록이 없습니다."
            return
        }

        state = .saving
        do {
            let request = RunningRecordRequest(
                userId: userId,
                planId: nil,
                totalDistance: rounded(summary.distanceKilometers),
                duration: summary.durationSeconds,
                pace: rounded(summary.paceMinutesPerKilometer),
                calories: rounded(summary.calories),
                routeDetail: "",
                gpsTraces: summary.route.map(Self.gpsTrace),
                badge: CommunityBadgeTier.tierName(
                    distanceKm: summary.distanceKilometers,
                    paceSeconds: paceSeconds(from: summary.paceMinutesPerKilometer)
                )
            )
            let response = try await runningService.saveRunningRecord(request)
            savedRecordId = response.runRecordId
            didSaveRecord = true
            state = .ready
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
            state = .result
        }
    }

    func loadPendingWatchSummaries() {
        do {
            pendingWatchSummaries = try watchWorkoutStore.pendingSummaries()
        } catch {
            pendingWatchSummaries = []
            errorMessage = Self.userFacingMessage(for: error)
        }
    }

    func saveWatchSummary(_ summary: WatchWorkoutPendingSummary) async {
        guard savingWatchSummaryId == nil else { return }
        guard let userId = authStore.userId else {
            errorMessage = "사용자 정보를 찾을 수 없습니다."
            return
        }

        savingWatchSummaryId = summary.id
        errorMessage = nil

        do {
            let response = try await runningService.saveRunningRecord(summary.makeRunningRecordRequest(userId: userId))
            try watchWorkoutStore.remove(id: summary.id)
            pendingWatchSummaries = try watchWorkoutStore.pendingSummaries()
            savedRecordId = response.runRecordId
            didSaveRecord = true
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
        }

        savingWatchSummaryId = nil
    }

    func discardWatchSummary(id: WatchWorkoutPendingSummary.ID) {
        do {
            try watchWorkoutStore.remove(id: id)
            pendingWatchSummaries = try watchWorkoutStore.pendingSummaries()
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
        }
    }

    func setError(_ message: String) {
        errorMessage = message
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshSummary()
            }
        }
    }

    private func refreshSummary() {
        summary = calculator.summary()
    }

    private func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private func paceSeconds(from minutesPerKilometer: Double) -> Int {
        Int((minutesPerKilometer * 60).rounded())
    }

    private static func gpsTrace(from sample: RunningLocationSample) -> GpsTraceRequest {
        GpsTraceRequest(latitude: sample.latitude, longitude: sample.longitude, time: gpsDateFormatter.string(from: sample.timestamp))
    }

    private static func userFacingMessage(for error: Error) -> String {
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                return "로그인이 만료되었습니다. 다시 로그인해 주세요."
            case .network:
                return "네트워크 연결을 확인한 뒤 다시 시도해 주세요."
            case .serverError(let statusCode, _):
                return "서버 오류로 러닝 기록을 저장하지 못했습니다. (\(statusCode))"
            case .decoding:
                return "서버 응답을 처리하지 못했습니다."
            case .invalidURL, .missingResponse:
                return "요청을 처리하지 못했습니다."
            }
        }

        if let storeError = error as? WatchWorkoutStoreError {
            return storeError.localizedDescription
        }

        return "러닝 기록을 처리하지 못했습니다."
    }

    private static let gpsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
