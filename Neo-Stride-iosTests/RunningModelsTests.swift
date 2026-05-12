import Foundation
import Testing
@testable import Neo_Stride_ios

struct RunningModelsTests {
    @Test func runningRecordRequestEncodesSnakeCaseFields() throws {
        let request = RunningRecordRequest(
            userId: 1,
            planId: nil,
            totalDistance: 3.25,
            duration: 1240,
            pace: 6.36,
            calories: 235.69,
            routeDetail: "",
            gpsTraces: [
                GpsTraceRequest(
                    latitude: 37.5665,
                    longitude: 126.978,
                    time: "2026-04-28 09:30:12",
                    heartRate: 151,
                    cadence: 172
                )
            ],
            badge: "silver"
        )

        let data = try JSONEncoder().encode(request)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["user_id"] as? Int == 1)
        #expect(object["plan_id"] is NSNull)
        #expect(object["total_distance"] as? Double == 3.25)
        #expect(object["pace"] as? Double == 6.36)
        #expect(object["badge"] as? String == "silver")
        #expect(object["route_detail"] as? String == "")
        let gpsTraces = try #require(object["gps_traces"] as? [[String: Any]])
        #expect(gpsTraces[0]["heart_rate"] as? Double == 151)
        #expect(gpsTraces[0]["cadence"] as? Double == 172)
    }

    @Test func runningRecordResponseDecodesSnakeCaseFields() throws {
        let json = """
        {
          "status": "success",
          "message": "러닝 기록이 저장되었습니다.",
          "run_record_id": 10,
          "created_at": "2026-04-28T14:30:00",
          "total_distance": 3.25,
          "duration": 1240,
          "pace": 6.36,
          "calories": 235.69,
          "gps_traces": [
            { "latitude": 37.5665, "longitude": 126.978, "time": "2026-04-28 09:30:12" }
          ],
          "segment_paces": [6.1, 6.4]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RunningRecordResponse.self, from: json)

        #expect(response.runRecordId == 10)
        #expect(response.createdAt == "2026-04-28T14:30:00")
        #expect(response.gpsTraces.count == 1)
        #expect(response.segmentPaces == [6.1, 6.4])
    }

    @Test func watchWorkoutSummaryPayloadParsesPropertyListNumbers() throws {
        let payload: [String: Any] = [
            "source": "watch",
            "workoutId": "watch-1",
            "startedAt": "2026-05-12T09:00:00.000Z",
            "endedAt": "2026-05-12T09:30:00.000Z",
            "durationSeconds": NSNumber(value: 1800),
            "distanceKilometers": NSNumber(value: 5.2),
            "averagePaceMinutesPerKilometer": NSNumber(value: 5.77),
            "activeEnergyKilocalories": NSNumber(value: 310.5),
            "averageHeartRate": NSNumber(value: 151.0),
            "averageCadenceStepsPerMinute": NSNumber(value: 172.0),
            "gpsTraces": [
                [
                    "latitude": NSNumber(value: 37.5665),
                    "longitude": NSNumber(value: 126.9780),
                    "time": "2026-05-12 18:00:00",
                    "heart_rate": NSNumber(value: 150.0),
                    "cadence": NSNumber(value: 171.0)
                ]
            ]
        ]

        let summary = try #require(WatchWorkoutPendingSummary(payload: payload))

        #expect(summary.id == "watch-1")
        #expect(summary.durationSeconds == 1800)
        #expect(summary.distanceKilometers == 5.2)
        #expect(summary.averageHeartRate == 151.0)
        #expect(summary.averageCadenceStepsPerMinute == 172.0)
        #expect(summary.gpsTraces.count == 1)
        #expect(summary.gpsTraces[0].heartRate == 150.0)
        #expect(summary.gpsTraces[0].cadence == 171.0)
    }

    @Test func watchWorkoutSummaryBuildsRunningRecordRequest() throws {
        let payload: [String: Any] = [
            "source": "watch",
            "workoutId": "watch-2",
            "startedAt": "2026-05-12T09:00:00.000Z",
            "endedAt": "2026-05-12T09:30:00.000Z",
            "durationSeconds": 1800,
            "distanceKilometers": 5.234,
            "averagePaceMinutesPerKilometer": 5.774,
            "activeEnergyKilocalories": 310.555,
            "averageHeartRate": 151.0,
            "averageCadenceStepsPerMinute": 172.0,
            "gpsTraces": [
                [
                    "latitude": 37.5665,
                    "longitude": 126.9780,
                    "time": "2026-05-12 18:00:00",
                    "heart_rate": 150.0,
                    "cadence": 171.0
                ]
            ]
        ]
        let summary = try #require(WatchWorkoutPendingSummary(payload: payload))

        let request = summary.makeRunningRecordRequest(userId: 7)
        let routeDetail = try #require(JSONSerialization.jsonObject(with: Data(request.routeDetail.utf8)) as? [String: Any])

        #expect(request.userId == 7)
        #expect(request.totalDistance == 5.23)
        #expect(request.pace == 5.77)
        #expect(request.calories == 310.56)
        #expect(request.gpsTraces.count == 1)
        #expect(request.gpsTraces[0].heartRate == 150.0)
        #expect(request.gpsTraces[0].cadence == 171.0)
        #expect(routeDetail["source"] as? String == "watchOS")
        #expect(routeDetail["averageHeartRate"] as? Double == 151.0)
        #expect(routeDetail["averageCadenceStepsPerMinute"] as? Double == 172.0)
    }

    @Test func watchWorkoutStoreDeduplicatesTransferredPayloads() throws {
        let suiteName = "watch-workout-store-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let store = WatchWorkoutStore(defaults: defaults, defaultsKey: "pending")
        let payload: [String: Any] = [
            "source": "watch",
            "workoutId": "watch-3",
            "startedAt": "2026-05-12T09:00:00.000Z",
            "endedAt": "2026-05-12T09:30:00.000Z",
            "durationSeconds": 1800,
            "distanceKilometers": 5.2,
            "averagePaceMinutesPerKilometer": 5.77,
            "activeEnergyKilocalories": 310.5,
            "averageHeartRate": 151.0
        ]
        let summary = try #require(WatchWorkoutPendingSummary(payload: payload))

        try store.upsert(summary)
        try store.upsert(summary)

        #expect(try store.pendingSummaries().map(\.id) == ["watch-3"])

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func watchWorkoutStoreClearsCorruptedPendingData() throws {
        let suiteName = "watch-workout-store-corrupt-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(Data("not-json".utf8), forKey: "pending")

        let store = WatchWorkoutStore(defaults: defaults, defaultsKey: "pending")

        #expect(throws: WatchWorkoutStoreError.corruptedData) {
            _ = try store.pendingSummaries()
        }
        #expect(defaults.data(forKey: "pending") == nil)

        defaults.removePersistentDomain(forName: suiteName)
    }
}
