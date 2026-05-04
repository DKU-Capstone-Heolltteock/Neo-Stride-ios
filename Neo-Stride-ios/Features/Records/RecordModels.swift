import Foundation

struct RunningRecord: Identifiable, Equatable, Hashable {
    let id: Int
    let createdAt: String?
    let totalDistance: Double
    let duration: Int
    let pace: Double
    let calories: Double
    let route: [GpsTraceRequest]
    let segmentPaces: [Double]

    init(response: RunningRecordResponse) {
        self.id = response.runRecordId
        self.createdAt = response.createdAt
        self.totalDistance = response.totalDistance ?? 0
        self.duration = response.duration ?? 0
        self.pace = response.pace ?? 0
        self.calories = response.calories ?? 0
        self.route = response.gpsTraces
        self.segmentPaces = response.segmentPaces
    }

    var distanceText: String {
        String(format: "%.2f km", totalDistance)
    }

    var durationText: String {
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let seconds = duration % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var paceText: String {
        pace > 0 ? String(format: "%.2f /km", pace) : "--"
    }

    var caloriesText: String {
        String(format: "%.0f kcal", calories)
    }

    var dateText: String {
        createdAt ?? "날짜 없음"
    }

    func isInMonth(_ month: RecordsMonth) -> Bool {
        guard let createdAt else { return false }
        let prefix = String(format: "%04d-%02d", month.year, month.month)
        return createdAt.hasPrefix(prefix)
    }
}

struct RecordsMonth: Equatable {
    private(set) var year: Int
    private(set) var month: Int

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
        normalize()
    }

    mutating func move(by offset: Int) {
        month += offset
        normalize()
    }

    private mutating func normalize() {
        while month < 1 {
            month += 12
            year -= 1
        }
        while month > 12 {
            month -= 12
            year += 1
        }
    }

    var title: String {
        "\(year)년 \(month)월"
    }
}
