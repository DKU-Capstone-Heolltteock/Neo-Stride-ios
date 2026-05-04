import Foundation

struct RunningLocationSample: Equatable, Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let horizontalAccuracy: Double
    let speed: Double
}

struct RunningSummary: Equatable {
    let distanceKilometers: Double
    let durationSeconds: Int
    let paceMinutesPerKilometer: Double
    let calories: Double
    let route: [RunningLocationSample]
}

struct RunningMetricsCalculator {
    private(set) var route: [RunningLocationSample] = []
    private(set) var distanceMeters: Double = 0

    private var startDate: Date?
    private var pauseStartedAt: Date?
    private var accumulatedPauseDuration: TimeInterval = 0

    private let minimumDistanceMeters: Double = 5
    private let maximumHorizontalAccuracy: Double = 20
    private let maximumSpeedMetersPerSecond: Double = 12

    mutating func start(at date: Date = Date()) {
        startDate = date
        pauseStartedAt = nil
        accumulatedPauseDuration = 0
        route = []
        distanceMeters = 0
    }

    mutating func pause(at date: Date = Date()) {
        guard pauseStartedAt == nil else { return }
        pauseStartedAt = date
    }

    mutating func resume(at date: Date = Date()) {
        guard let pauseStartedAt else { return }
        accumulatedPauseDuration += date.timeIntervalSince(pauseStartedAt)
        self.pauseStartedAt = nil
    }

    mutating func reset() {
        route = []
        distanceMeters = 0
        startDate = nil
        pauseStartedAt = nil
        accumulatedPauseDuration = 0
    }

    mutating func add(sample: RunningLocationSample) {
        guard sample.horizontalAccuracy >= 0, sample.horizontalAccuracy <= maximumHorizontalAccuracy else { return }
        guard sample.speed <= maximumSpeedMetersPerSecond || sample.speed < 0 else { return }

        guard let previous = route.last else {
            route.append(sample)
            return
        }

        let delta = Self.distanceMeters(from: previous, to: sample)
        guard delta >= minimumDistanceMeters else { return }

        distanceMeters += delta
        route.append(sample)
    }

    func summary(at date: Date = Date()) -> RunningSummary {
        let elapsed = elapsedSeconds(at: date)
        let distanceKilometers = distanceMeters / 1000
        let pace = distanceKilometers > 0 ? Double(elapsed) / 60.0 / distanceKilometers : 0
        return RunningSummary(
            distanceKilometers: distanceKilometers,
            durationSeconds: elapsed,
            paceMinutesPerKilometer: pace,
            calories: Self.estimatedCalories(distanceKilometers: distanceKilometers),
            route: route
        )
    }

    private func elapsedSeconds(at date: Date) -> Int {
        guard let startDate else { return 0 }
        let activePause = pauseStartedAt.map { date.timeIntervalSince($0) } ?? 0
        let elapsed = date.timeIntervalSince(startDate) - accumulatedPauseDuration - activePause
        return max(0, Int(elapsed.rounded()))
    }

    static func distanceMeters(from start: RunningLocationSample, to end: RunningLocationSample) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLat = (end.latitude - start.latitude) * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180

        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusMeters * c
    }

    static func estimatedCalories(distanceKilometers: Double, bodyWeightKilograms: Double = 70) -> Double {
        distanceKilometers * bodyWeightKilograms * 1.036
    }
}
