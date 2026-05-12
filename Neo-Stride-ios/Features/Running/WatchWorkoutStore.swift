import Foundation

enum WatchWorkoutStoreError: Error, LocalizedError, Equatable {
    case corruptedData
    case encodingFailed
    case persistenceFailed

    var errorDescription: String? {
        switch self {
        case .corruptedData:
            return "저장된 워치 기록을 읽을 수 없습니다."
        case .encodingFailed:
            return "워치 기록을 저장 가능한 형식으로 변환할 수 없습니다."
        case .persistenceFailed:
            return "워치 기록을 기기에 저장하지 못했습니다."
        }
    }
}

final class WatchWorkoutStore {
    static let shared = WatchWorkoutStore()

    private let defaults: UserDefaults
    private let defaultsKey: String

    init(
        defaults: UserDefaults = .standard,
        defaultsKey: String = "watchWorkout.pendingSummaries"
    ) {
        self.defaults = defaults
        self.defaultsKey = defaultsKey
    }

    func pendingSummaries() throws -> [WatchWorkoutPendingSummary] {
        guard let data = defaults.data(forKey: defaultsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WatchWorkoutPendingSummary].self, from: data)
        } catch {
            defaults.removeObject(forKey: defaultsKey)
            throw WatchWorkoutStoreError.corruptedData
        }
    }

    func upsert(_ summary: WatchWorkoutPendingSummary) throws {
        var summaries = try pendingSummaries().filter { $0.id != summary.id }
        summaries.insert(summary, at: 0)
        try save(Array(summaries.prefix(10)))
    }

    func remove(id: WatchWorkoutPendingSummary.ID) throws {
        try save(pendingSummaries().filter { $0.id != id })
    }

    private func save(_ summaries: [WatchWorkoutPendingSummary]) throws {
        guard let data = try? JSONEncoder().encode(summaries) else {
            throw WatchWorkoutStoreError.encodingFailed
        }

        defaults.set(data, forKey: defaultsKey)
        guard defaults.synchronize() else {
            throw WatchWorkoutStoreError.persistenceFailed
        }
    }
}

struct WatchWorkoutPendingSummary: Codable, Equatable, Identifiable {
    let id: String
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: Int
    let distanceKilometers: Double
    let averagePaceMinutesPerKilometer: Double
    let activeEnergyKilocalories: Double
    let averageHeartRate: Double
    let averageCadenceStepsPerMinute: Double?
    let gpsTraces: [GpsTraceRequest]

    init?(
        payload: [String: Any],
        dateFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()
    ) {
        guard
            payload["source"] as? String == "watch",
            let startedAtText = payload["startedAt"] as? String,
            let endedAtText = payload["endedAt"] as? String,
            let startedAt = dateFormatter.date(from: startedAtText),
            let endedAt = dateFormatter.date(from: endedAtText),
            let durationSeconds = Self.intValue(payload["durationSeconds"]),
            let distanceKilometers = Self.doubleValue(payload["distanceKilometers"]),
            let averagePaceMinutesPerKilometer = Self.doubleValue(payload["averagePaceMinutesPerKilometer"]),
            let activeEnergyKilocalories = Self.doubleValue(payload["activeEnergyKilocalories"]),
            let averageHeartRate = Self.doubleValue(payload["averageHeartRate"])
        else {
            return nil
        }

        self.id = payload["workoutId"] as? String ?? "\(startedAtText)-\(durationSeconds)-\(distanceKilometers)"
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.distanceKilometers = distanceKilometers
        self.averagePaceMinutesPerKilometer = averagePaceMinutesPerKilometer
        self.activeEnergyKilocalories = activeEnergyKilocalories
        self.averageHeartRate = averageHeartRate
        self.averageCadenceStepsPerMinute = Self.doubleValue(payload["averageCadenceStepsPerMinute"])
        self.gpsTraces = Self.gpsTraces(payload["gpsTraces"])
    }

    func makeRunningRecordRequest(userId: Int) -> RunningRecordRequest {
        RunningRecordRequest(
            userId: userId,
            planId: nil,
            totalDistance: rounded(distanceKilometers),
            duration: durationSeconds,
            pace: rounded(averagePaceMinutesPerKilometer),
            calories: rounded(activeEnergyKilocalories),
            routeDetail: routeDetailJSON(),
            gpsTraces: gpsTraces,
            badge: CommunityBadgeTier.tierName(
                distanceKm: distanceKilometers,
                paceSeconds: Int((averagePaceMinutesPerKilometer * 60).rounded())
            )
        )
    }

    private func routeDetailJSON() -> String {
        let detail = WatchWorkoutRouteDetail(
            source: "watchOS",
            startedAt: Self.isoDateFormatter.string(from: startedAt),
            endedAt: Self.isoDateFormatter.string(from: endedAt),
            averageHeartRate: averageHeartRate,
            averageCadenceStepsPerMinute: averageCadenceStepsPerMinute
        )

        guard
            let data = try? JSONEncoder().encode(detail),
            let text = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return text
    }

    private func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private static func gpsTraces(_ value: Any?) -> [GpsTraceRequest] {
        guard let rawTraces = value as? [[String: Any]] else { return [] }
        return rawTraces.compactMap { rawTrace in
            guard
                let latitude = doubleValue(rawTrace["latitude"]),
                let longitude = doubleValue(rawTrace["longitude"]),
                let time = rawTrace["time"] as? String
            else {
                return nil
            }
            return GpsTraceRequest(
                latitude: latitude,
                longitude: longitude,
                time: time,
                heartRate: doubleValue(rawTrace["heart_rate"]),
                cadence: doubleValue(rawTrace["cadence"])
            )
        }
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let value = value as? Int { return value }
        if let value = value as? NSNumber { return value.intValue }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

private struct WatchWorkoutRouteDetail: Encodable {
    let source: String
    let startedAt: String
    let endedAt: String
    let averageHeartRate: Double
    let averageCadenceStepsPerMinute: Double?
}
