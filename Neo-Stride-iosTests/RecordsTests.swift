import Foundation
import Testing
@testable import Neo_Stride_ios

struct RecordsTests {
    @Test func monthlyRecordResponseDecodesToDisplayRecord() throws {
        let json = """
        {
          "run_record_id": 10,
          "created_at": "2026-04-28T14:30:00",
          "total_distance": 3.25,
          "duration": 1240,
          "pace": 6.36,
          "calories": 235.69,
          "gps_traces": [],
          "segment_paces": []
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RunningRecordResponse.self, from: json)
        let record = RunningRecord(response: response)

        #expect(record.id == 10)
        #expect(record.distanceText == "3.25 km")
        #expect(record.durationText == "20:40")
        #expect(record.paceText == "6.36 /km")
    }

    @Test func detailRecordKeepsGpsRouteForMap() throws {
        let json = """
        {
          "run_record_id": 11,
          "created_at": "2026-04-28T15:30:00",
          "total_distance": 1.0,
          "duration": 600,
          "pace": 10.0,
          "calories": 70.0,
          "gps_traces": [
            { "latitude": 37.5665, "longitude": 126.978, "time": "2026-04-28 09:30:12" },
            { "latitude": 37.5675, "longitude": 126.979, "time": "2026-04-28 09:31:12" }
          ],
          "segment_paces": [10.0]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(RunningRecordResponse.self, from: json)
        let record = RunningRecord(response: response)

        #expect(record.route.count == 2)
        #expect(record.route[0].latitude == 37.5665)
    }

    @Test func recordsMonthSelectionMovesBetweenMonths() throws {
        var month = RecordsMonth(year: 2026, month: 5)

        month.move(by: -1)
        #expect(month.year == 2026)
        #expect(month.month == 4)

        month.move(by: -5)
        #expect(month.year == 2025)
        #expect(month.month == 11)
    }

    @Test func runningRecordCanBeUsedAsNavigationPathValue() throws {
        let record = RunningRecord(response: RunningRecordResponse(runRecordId: 1))
        let set: Set<RunningRecord> = [record]

        #expect(set.contains(record))
    }

    @Test func runningRecordMatchesSelectedMonthByCreatedAtPrefix() throws {
        let record = RunningRecord(response: RunningRecordResponse(runRecordId: 1, createdAt: "2026-04-28T14:30:00"))

        #expect(record.isInMonth(RecordsMonth(year: 2026, month: 4)))
        #expect(!record.isInMonth(RecordsMonth(year: 2026, month: 5)))
    }
}
