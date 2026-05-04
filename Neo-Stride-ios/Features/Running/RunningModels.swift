import Foundation

struct GpsTraceRequest: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let time: String
}

struct RunningRecordRequest: Encodable, Equatable {
    let userId: Int
    let planId: Int?
    let totalDistance: Double
    let duration: Int
    let pace: Double
    let calories: Double
    let routeDetail: String
    let gpsTraces: [GpsTraceRequest]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case planId = "plan_id"
        case totalDistance = "total_distance"
        case duration
        case pace
        case calories
        case routeDetail = "route_detail"
        case gpsTraces = "gps_traces"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encode(planId, forKey: .planId)
        try container.encode(totalDistance, forKey: .totalDistance)
        try container.encode(duration, forKey: .duration)
        try container.encode(pace, forKey: .pace)
        try container.encode(calories, forKey: .calories)
        try container.encode(routeDetail, forKey: .routeDetail)
        try container.encode(gpsTraces, forKey: .gpsTraces)
    }
}

struct RunningRecordResponse: Decodable, Equatable, Identifiable {
    var id: Int { runRecordId }

    let status: String?
    let message: String?
    let runRecordId: Int
    let createdAt: String?
    let totalDistance: Double?
    let duration: Int?
    let pace: Double?
    let calories: Double?
    let gpsTraces: [GpsTraceRequest]
    let segmentPaces: [Double]

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case runRecordId = "run_record_id"
        case createdAt = "created_at"
        case totalDistance = "total_distance"
        case duration
        case pace
        case calories
        case gpsTraces = "gps_traces"
        case segmentPaces = "segment_paces"
    }

    init(
        status: String? = nil,
        message: String? = nil,
        runRecordId: Int,
        createdAt: String? = nil,
        totalDistance: Double? = nil,
        duration: Int? = nil,
        pace: Double? = nil,
        calories: Double? = nil,
        gpsTraces: [GpsTraceRequest] = [],
        segmentPaces: [Double] = []
    ) {
        self.status = status
        self.message = message
        self.runRecordId = runRecordId
        self.createdAt = createdAt
        self.totalDistance = totalDistance
        self.duration = duration
        self.pace = pace
        self.calories = calories
        self.gpsTraces = gpsTraces
        self.segmentPaces = segmentPaces
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        self.runRecordId = try container.decode(Int.self, forKey: .runRecordId)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.totalDistance = try container.decodeIfPresent(Double.self, forKey: .totalDistance)
        self.duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        self.pace = try container.decodeIfPresent(Double.self, forKey: .pace)
        self.calories = try container.decodeIfPresent(Double.self, forKey: .calories)
        self.gpsTraces = try container.decodeIfPresent([GpsTraceRequest].self, forKey: .gpsTraces) ?? []
        self.segmentPaces = try container.decodeIfPresent([Double].self, forKey: .segmentPaces) ?? []
    }
}
