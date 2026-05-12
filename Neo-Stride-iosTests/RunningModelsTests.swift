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
            gpsTraces: [GpsTraceRequest(latitude: 37.5665, longitude: 126.978, time: "2026-04-28 09:30:12")],
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
        #expect(object["gps_traces"] != nil)
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
}
