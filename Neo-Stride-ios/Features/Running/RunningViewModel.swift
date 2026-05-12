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

    private let runningService: RunningService
    private let authStore: AuthStore
    private var calculator = RunningMetricsCalculator()
    private var timer: Timer?

    init(runningService: RunningService, authStore: AuthStore) {
        self.runningService = runningService
        self.authStore = authStore
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
            errorMessage = "러닝 기록 저장 실패"
            state = .result
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

    private static let gpsDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
