import Combine
import CoreLocation
import Foundation
import HealthKit
import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var viewModel = WatchRunningViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                metricsGrid
                controls
                statusMessage
            }
            .padding(.horizontal, 2)
        }
        .containerBackground(.black.gradient, for: .navigation)
        .task {
            await viewModel.requestAuthorization()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Neo Stride")
                .font(.headline)
            Text(viewModel.state.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var metricsGrid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                metric("시간", viewModel.formattedElapsed)
                metric("거리", String(format: "%.2f km", viewModel.distanceKilometers))
            }
            HStack(spacing: 8) {
                metric("페이스", viewModel.formattedPace)
                metric("심박", viewModel.formattedHeartRate)
            }
            HStack(spacing: 8) {
                metric("케이던스", viewModel.formattedCadence)
                metric("GPS", "\(viewModel.gpsTraceCount) pts")
            }
            metric("칼로리", String(format: "%.0f kcal", viewModel.activeEnergyKilocalories))
        }
    }

    private var controls: some View {
        VStack(spacing: 8) {
            switch viewModel.state {
            case .ready, .finished:
                Button {
                    Task { await viewModel.startWorkout() }
                } label: {
                    Label("시작", systemImage: "figure.run")
                }
                .buttonStyle(.borderedProminent)
            case .running:
                HStack {
                    Button {
                        viewModel.pauseWorkout()
                    } label: {
                        Image(systemName: "pause.fill")
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.endWorkout() }
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                }
            case .paused:
                HStack {
                    Button {
                        viewModel.resumeWorkout()
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.endWorkout() }
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                }
            case .saving:
                ProgressView()
            }
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        if let message = viewModel.message {
            Text(message)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.headline, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

@MainActor
final class WatchRunningViewModel: NSObject, ObservableObject {
    enum State {
        case ready
        case running
        case paused
        case saving
        case finished

        var title: String {
            switch self {
            case .ready:
                return "준비"
            case .running:
                return "측정 중"
            case .paused:
                return "일시정지"
            case .saving:
                return "저장 중"
            case .finished:
                return "전송 완료"
            }
        }
    }

    @Published private(set) var state: State = .ready
    @Published private(set) var elapsedSeconds = 0
    @Published private(set) var distanceKilometers = 0.0
    @Published private(set) var heartRate = 0.0
    @Published private(set) var activeEnergyKilocalories = 0.0
    @Published private(set) var stepCount = 0.0
    @Published private(set) var gpsTraceCount = 0
    @Published private(set) var message: String?

    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var startDate: Date?
    private var pauseDate: Date?
    private var accumulatedPauseDuration: TimeInterval = 0
    private var timer: Timer?
    private var gpsTraces: [WatchGpsTracePayload] = []
    private var workoutId = UUID().uuidString

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
    }

    var formattedElapsed: String {
        Self.formatDuration(elapsedSeconds)
    }

    var formattedPace: String {
        guard distanceKilometers > 0 else { return "--" }
        return String(format: "%.2f/km", averagePaceMinutesPerKilometer)
    }

    var formattedHeartRate: String {
        heartRate > 0 ? "\(Int(heartRate.rounded())) bpm" : "--"
    }

    var formattedCadence: String {
        guard let cadence = averageCadenceStepsPerMinute else { return "--" }
        return "\(Int(cadence.rounded())) spm"
    }

    private var averagePaceMinutesPerKilometer: Double {
        guard distanceKilometers > 0 else { return 0 }
        return Double(elapsedSeconds) / 60.0 / distanceKilometers
    }

    private var averageCadenceStepsPerMinute: Double? {
        guard elapsedSeconds > 0, stepCount > 0 else { return nil }
        return stepCount / (Double(elapsedSeconds) / 60.0)
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            message = "HealthKit을 사용할 수 없습니다."
            return false
        }

        locationManager.requestWhenInUseAuthorization()

        let shareTypes: Set = [
            HKObjectType.workoutType()
        ]
        let readTypes: Set = [
            HKObjectType.workoutType(),
            HKQuantityType(.heartRate),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.stepCount)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: shareTypes, read: readTypes)
            guard healthStore.authorizationStatus(for: HKObjectType.workoutType()) != .sharingDenied else {
                message = "운동 기록 저장 권한이 필요합니다."
                return false
            }
            message = nil
            return true
        } catch {
            message = "건강 데이터 권한이 필요합니다."
            return false
        }
    }

    func startWorkout() async {
        guard await requestAuthorization() else {
            state = .ready
            return
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .running
        configuration.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            session.delegate = self
            builder.delegate = self

            self.session = session
            self.builder = builder
            resetMetrics()

            let now = Date()
            startDate = now
            session.startActivity(with: now)
            try await builder.beginCollection(at: now)
            state = .running
            startTimer()
            startLocationUpdates()
        } catch {
            message = "운동 세션을 시작할 수 없습니다."
            state = .ready
        }
    }

    func pauseWorkout() {
        guard state == .running else { return }
        pauseDate = Date()
        session?.pause()
        state = .paused
        stopTimer()
        locationManager.stopUpdatingLocation()
    }

    func resumeWorkout() {
        guard state == .paused else { return }
        if let pauseDate {
            accumulatedPauseDuration += Date().timeIntervalSince(pauseDate)
        }
        pauseDate = nil
        session?.resume()
        state = .running
        startTimer()
        startLocationUpdates()
    }

    func endWorkout() async {
        guard let builder else {
            message = "저장할 운동 세션이 없습니다."
            state = .ready
            return
        }
        state = .saving
        stopTimer()
        locationManager.stopUpdatingLocation()
        session?.end()

        do {
            let endDate = Date()
            try await builder.endCollection(at: endDate)
            _ = try await builder.finishWorkout()
            refreshStatistics()
            let transferResult = WatchWorkoutTransfer.shared.send(
                WatchWorkoutSummaryPayload(
                    workoutId: workoutId,
                    startedAt: startDate ?? endDate,
                    endedAt: endDate,
                    durationSeconds: elapsedSeconds,
                    distanceKilometers: distanceKilometers,
                    averagePaceMinutesPerKilometer: averagePaceMinutesPerKilometer,
                    activeEnergyKilocalories: activeEnergyKilocalories,
                    averageHeartRate: heartRate,
                    averageCadenceStepsPerMinute: averageCadenceStepsPerMinute,
                    gpsTraces: gpsTraces
                )
            )
            message = transferResult.message
            state = .finished
        } catch {
            message = "운동 기록 저장에 실패했습니다."
            state = .finished
        }
    }

    private func resetMetrics() {
        elapsedSeconds = 0
        distanceKilometers = 0
        heartRate = 0
        activeEnergyKilocalories = 0
        stepCount = 0
        gpsTraceCount = 0
        gpsTraces = []
        workoutId = UUID().uuidString
        message = nil
        pauseDate = nil
        accumulatedPauseDuration = 0
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshElapsed()
                self?.refreshStatistics()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        refreshElapsed()
    }

    private func refreshElapsed() {
        guard let startDate else {
            elapsedSeconds = 0
            return
        }

        let activePause = pauseDate.map { Date().timeIntervalSince($0) } ?? 0
        elapsedSeconds = max(0, Int((Date().timeIntervalSince(startDate) - accumulatedPauseDuration - activePause).rounded()))
    }

    private func refreshStatistics() {
        guard let builder else { return }

        let heartRateType = HKQuantityType(.heartRate)
        if let quantity = builder.statistics(for: heartRateType)?.mostRecentQuantity() {
            heartRate = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        }

        let distanceType = HKQuantityType(.distanceWalkingRunning)
        if let quantity = builder.statistics(for: distanceType)?.sumQuantity() {
            distanceKilometers = quantity.doubleValue(for: .meter()) / 1000
        }

        let energyType = HKQuantityType(.activeEnergyBurned)
        if let quantity = builder.statistics(for: energyType)?.sumQuantity() {
            activeEnergyKilocalories = quantity.doubleValue(for: .kilocalorie())
        }

        let stepType = HKQuantityType(.stepCount)
        if let quantity = builder.statistics(for: stepType)?.sumQuantity() {
            stepCount = quantity.doubleValue(for: .count())
        }
    }

    private func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else {
            message = "위치 서비스를 사용할 수 없습니다."
            return
        }

        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            message = "러닝 경로를 기록하려면 위치 권한이 필요합니다."
            return
        @unknown default:
            message = "위치 권한 상태를 확인할 수 없습니다."
            return
        }

        locationManager.startUpdatingLocation()
    }

    private func appendLocation(_ location: CLLocation) {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 30 else { return }
        guard location.speed <= 12 || location.speed < 0 else { return }

        let trace = WatchGpsTracePayload(
            location: location,
            heartRate: heartRate > 0 ? heartRate : nil,
            cadence: averageCadenceStepsPerMinute
        )
        if let previous = gpsTraces.last, previous.distanceMeters(to: trace) < 5 {
            return
        }

        gpsTraces.append(trace)
        if gpsTraces.count > 2_000 {
            gpsTraces.removeFirst(gpsTraces.count - 2_000)
        }
        gpsTraceCount = gpsTraces.count
    }

    private static func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension WatchRunningViewModel: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        Task { @MainActor in
            self.message = "운동 세션 오류가 발생했습니다."
            self.state = .finished
        }
    }
}

extension WatchRunningViewModel: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            self.refreshStatistics()
        }
    }
}

extension WatchRunningViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            locations.forEach { self.appendLocation($0) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.message = "GPS 위치를 수집할 수 없습니다."
        }
    }
}

struct WatchGpsTracePayload {
    let latitude: Double
    let longitude: Double
    let time: String
    let heartRate: Double?
    let cadence: Double?

    init(location: CLLocation, heartRate: Double?, cadence: Double?) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        time = Self.dateFormatter.string(from: location.timestamp)
        self.heartRate = heartRate
        self.cadence = cadence
    }

    var dictionary: [String: Any] {
        var payload: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "time": time
        ]

        if let heartRate {
            payload["heart_rate"] = heartRate
        }
        if let cadence {
            payload["cadence"] = cadence
        }

        return payload
    }

    func distanceMeters(to other: WatchGpsTracePayload) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let deltaLat = (other.latitude - latitude) * .pi / 180
        let deltaLon = (other.longitude - longitude) * .pi / 180
        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}

struct WatchWorkoutSummaryPayload {
    let workoutId: String
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: Int
    let distanceKilometers: Double
    let averagePaceMinutesPerKilometer: Double
    let activeEnergyKilocalories: Double
    let averageHeartRate: Double
    let averageCadenceStepsPerMinute: Double?
    let gpsTraces: [WatchGpsTracePayload]

    var dictionary: [String: Any] {
        var payload: [String: Any] = [
            "source": "watch",
            "workoutId": workoutId,
            "startedAt": Self.dateFormatter.string(from: startedAt),
            "endedAt": Self.dateFormatter.string(from: endedAt),
            "durationSeconds": durationSeconds,
            "distanceKilometers": distanceKilometers,
            "averagePaceMinutesPerKilometer": averagePaceMinutesPerKilometer,
            "activeEnergyKilocalories": activeEnergyKilocalories,
            "averageHeartRate": averageHeartRate,
            "gpsTraces": gpsTraces.map(\.dictionary)
        ]

        if let averageCadenceStepsPerMinute {
            payload["averageCadenceStepsPerMinute"] = averageCadenceStepsPerMinute
        }

        return payload
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

final class WatchWorkoutTransfer: NSObject, WCSessionDelegate {
    static let shared = WatchWorkoutTransfer()

    private override init() {
        super.init()
        activate()
    }

    func send(_ payload: WatchWorkoutSummaryPayload) -> WatchWorkoutTransferResult {
        guard WCSession.isSupported() else {
            return .unsupported
        }

        let didActivate = activate()
        let dictionary = payload.dictionary

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(dictionary, replyHandler: nil) { error in
                NSLog("Failed to send live watch workout message: \(error.localizedDescription)")
            }
        }

        WCSession.default.transferUserInfo(dictionary)

        if WCSession.default.isReachable {
            return .sentLiveAndQueued
        }
        return didActivate ? .queued : .queuedBeforeActivation
    }

    @discardableResult
    private func activate() -> Bool {
        guard WCSession.isSupported() else { return false }
        guard WCSession.default.delegate == nil else { return true }
        WCSession.default.delegate = self
        WCSession.default.activate()
        return true
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}
}

enum WatchWorkoutTransferResult {
    case sentLiveAndQueued
    case queued
    case queuedBeforeActivation
    case unsupported

    var message: String {
        switch self {
        case .sentLiveAndQueued:
            return "iPhone으로 기록을 전송했습니다."
        case .queued:
            return "iPhone이 연결되면 기록을 전송합니다."
        case .queuedBeforeActivation:
            return "전송 준비 중입니다. iPhone 연결 후 다시 확인해 주세요."
        case .unsupported:
            return "이 기기에서는 iPhone 전송을 사용할 수 없습니다."
        }
    }
}

#Preview {
    ContentView()
}
