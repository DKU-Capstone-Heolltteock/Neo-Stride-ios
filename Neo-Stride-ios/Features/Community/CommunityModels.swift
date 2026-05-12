import Foundation

enum CommunitySection: String, CaseIterable, Identifiable, Hashable {
    case feed
    case tip
    case search
    case event
    case notification
    case myPage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .feed: return "피드"
        case .tip: return "팁"
        case .search: return "검색"
        case .event: return "이벤트"
        case .notification: return "알림"
        case .myPage: return "마이페이지"
        }
    }

    var systemImage: String {
        switch self {
        case .feed: return "text.bubble"
        case .tip: return "lightbulb"
        case .search: return "magnifyingglass"
        case .event: return "gift"
        case .notification: return "bell"
        case .myPage: return "person.crop.circle"
        }
    }

    var isBottomTab: Bool {
        switch self {
        case .feed, .tip, .search, .event: return true
        case .notification, .myPage: return false
        }
    }

    static let bottomTabs: [CommunitySection] = [.feed, .tip, .search, .event]
}

enum CommunityTipCategory: String, CaseIterable, Identifiable, Hashable {
    case all = "ALL"
    case free = "FREE"
    case training = "TRAINING"
    case course = "COURSE"
    case gear = "GEAR"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "전체"
        case .free: return "자유"
        case .training: return "훈련"
        case .course: return "코스"
        case .gear: return "장비"
        }
    }
}

enum CommunityFeedPrivacy: String, CaseIterable, Identifiable, Hashable {
    case `private` = "PRIVATE"
    case friend = "FRIEND"
    case badgeHolder = "BADGE_HOLDER"
    case `public` = "PUBLIC"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .private: return "나만 보기"
        case .friend: return "친구"
        case .badgeHolder: return "배지홀더"
        case .public: return "전체"
        }
    }
}

struct CommunityTagUser: Identifiable, Codable, Equatable, Hashable {
    let userId: Int
    let nickname: String

    var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId
        case nickname
    }
}

struct CommunityFeedItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let username: String
    let timeText: String
    let title: String
    let content: String
    let tagCount: Int
    let likeCount: Int
    let commentCount: Int
    let distanceText: String
    let durationText: String
    let paceText: String
    let isMapVisible: Bool

    init(
        id: UUID = UUID(),
        username: String,
        timeText: String,
        title: String,
        content: String = "",
        tagCount: Int,
        likeCount: Int,
        commentCount: Int,
        distanceText: String,
        durationText: String,
        paceText: String,
        isMapVisible: Bool = true
    ) {
        self.id = id
        self.username = username
        self.timeText = timeText
        self.title = title
        self.content = content
        self.tagCount = tagCount
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.distanceText = distanceText
        self.durationText = durationText
        self.paceText = paceText
        self.isMapVisible = isMapVisible
    }

    static let samples: [CommunityFeedItem] = [
        CommunityFeedItem(
            username: "JinzaYoungjae3218",
            timeText: "7분 전",
            title: "오운완",
            content: "퇴근 후 가볍게 뛰려다 기록까지 챙겼어요.",
            tagCount: 2,
            likeCount: 3,
            commentCount: 2,
            distanceText: "11.8km",
            durationText: "37:49",
            paceText: "6:24/km"
        ),
        CommunityFeedItem(
            username: "RunnerNeo",
            timeText: "15분 전",
            title: "오늘 러닝 완료",
            content: "페이스 유지 성공. 내일은 코스 바꿔볼 예정!",
            tagCount: 5,
            likeCount: 12,
            commentCount: 4,
            distanceText: "5.9km",
            durationText: "28:10",
            paceText: "4:46/km"
        )
    ]
}

extension CommunityFeedItem {
    init(uploadRequest request: CommunityFeedUploadRequest, username: String) {
        self.init(
            username: username,
            timeText: "방금 전",
            title: request.title,
            content: request.content,
            tagCount: request.tagCount,
            likeCount: 0,
            commentCount: 0,
            distanceText: String(format: "%.1fkm", request.distance),
            durationText: request.runningTime,
            paceText: request.pace,
            isMapVisible: request.mapVisible
        )
    }

    init(uploadResponse response: CommunityFeedUploadResponse) {
        self.init(
            username: response.nickname,
            timeText: "방금 전",
            title: response.title,
            content: response.content,
            tagCount: response.taggedCount,
            likeCount: response.likeCount,
            commentCount: response.commentCount,
            distanceText: response.distance,
            durationText: response.duration,
            paceText: response.pace,
            isMapVisible: response.mapVisible
        )
    }
}

struct CommunitySearchItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let section: CommunitySection
    let tipCategory: CommunityTipCategory?

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        section: CommunitySection,
        tipCategory: CommunityTipCategory? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.section = section
        self.tipCategory = tipCategory
    }

    static let samples: [CommunitySearchItem] = [
        CommunitySearchItem(title: "JinzaYoungjae3218", subtitle: "오운완 피드", section: .feed),
        CommunitySearchItem(title: "GosuRunner444", subtitle: "훈련, 인터벌로 해보세요!", section: .tip, tipCategory: .training),
        CommunitySearchItem(title: "onlyRunning1234", subtitle: "단대 근처 러닝 장소 추천해요", section: .tip, tipCategory: .course),
        CommunitySearchItem(title: "자유롭게 러닝 얘기해요", subtitle: "자유 게시글", section: .tip, tipCategory: .free),
        CommunitySearchItem(title: "러닝화 추천", subtitle: "장비 게시글", section: .tip, tipCategory: .gear),
        CommunitySearchItem(title: "RunningLover", subtitle: "친구 999+", section: .myPage),
        CommunitySearchItem(title: "walkingphobia", subtitle: "친구 999+", section: .myPage),
        CommunitySearchItem(title: "CrazyRun", subtitle: "친구 999+", section: .myPage),
        CommunitySearchItem(title: "UngCheon1004", subtitle: "친구 5", section: .notification),
        CommunitySearchItem(title: "YoonHyeon7942", subtitle: "친구 7", section: .notification)
    ]
}

struct CommunityTipItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let author: String
    let category: CommunityTipCategory
    let summary: String

    init(id: UUID = UUID(), title: String, author: String, category: CommunityTipCategory, summary: String) {
        self.id = id
        self.title = title
        self.author = author
        self.category = category
        self.summary = summary
    }

    static let samples: [CommunityTipItem] = [
        CommunityTipItem(title: "인터벌 훈련은 짧게 시작하세요", author: "GosuRunner444", category: .training, summary: "고강도 구간과 회복 구간을 번갈아 반복합니다."),
        CommunityTipItem(title: "단대 근처 러닝 코스 추천", author: "onlyRunning1234", category: .course, summary: "초보자는 평지 위주 코스부터 시작해보세요."),
        CommunityTipItem(title: "러닝화 교체 주기", author: "RunnerNeo", category: .gear, summary: "쿠션이 무너지면 무릎 피로가 빨리 옵니다."),
        CommunityTipItem(title: "자유롭게 러닝 얘기해요", author: "NeoStride", category: .free, summary: "오늘의 컨디션과 목표를 공유해보세요.")
    ]
}

enum CommunityFriendStatus: String, CaseIterable, Identifiable, Hashable, Codable {
    case friends
    case sent
    case received
    case blocked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .friends: return "친구"
        case .sent: return "보낸 요청"
        case .received: return "받은 요청"
        case .blocked: return "차단"
        }
    }
}

enum CommunityFriendAction: String, CaseIterable, Identifiable, Hashable {
    case cancel
    case accept
    case reject
    case block
    case unblock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cancel: return "요청 취소"
        case .accept: return "수락"
        case .reject: return "거절"
        case .block: return "차단"
        case .unblock: return "차단 해제"
        }
    }
}

enum CommunityActivityFilter: String, CaseIterable, Identifiable, Hashable {
    case myFeeds = "me"
    case tagged = "tagged"
    case comments = "comments"
    case likes = "likes"
    case bookmarks = "bookmarks"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .myFeeds: return "내가 쓴 피드"
        case .tagged: return "나를 태그한 피드"
        case .comments: return "내가 쓴 댓글"
        case .likes: return "내가 한 좋아요"
        case .bookmarks: return "내가 한 북마크"
        }
    }
}

enum CommunityBadgeTier: String, CaseIterable, Identifiable, Codable, Hashable {
    case none
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    case master
    case challenger

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "UnRanked"
        case .bronze: return "브론즈"
        case .silver: return "실버"
        case .gold: return "골드"
        case .platinum: return "플래티넘"
        case .diamond: return "다이아"
        case .master: return "마스터"
        case .challenger: return "챌린저"
        }
    }

    static func tierName(distanceKm: Double, paceSeconds: Int) -> String {
        let distances = [1.0, 3.0, 5.0, 10.0, 20.0, 40.0]
        let bronze = [340, 360, 380, 410, 450, 510]
        let silver = [315, 335, 355, 385, 425, 485]
        let gold = [290, 310, 330, 360, 400, 460]
        let platinum = [270, 290, 310, 340, 380, 440]
        let diamond = [250, 270, 290, 320, 360, 420]
        let master = [230, 250, 270, 300, 340, 400]
        let challenger = [210, 230, 250, 280, 320, 380]

        var index = 0
        if distanceKm <= distances[0] {
            index = 0
        } else if distanceKm >= distances[distances.count - 1] {
            index = distances.count - 2
        } else {
            while index < distances.count - 2 && distanceKm > distances[index + 1] {
                index += 1
            }
        }

        func interpolated(_ values: [Int]) -> Double {
            let x1 = distances[index]
            let x2 = distances[index + 1]
            let y1 = Double(values[index])
            let y2 = Double(values[index + 1])
            if distanceKm <= x1 { return y1 }
            if distanceKm >= x2 { return y2 }
            return y1 + (distanceKm - x1) * (y2 - y1) / (x2 - x1)
        }

        if Double(paceSeconds) <= interpolated(challenger) { return "challenger" }
        if Double(paceSeconds) <= interpolated(master) { return "master" }
        if Double(paceSeconds) <= interpolated(diamond) { return "diamond" }
        if Double(paceSeconds) <= interpolated(platinum) { return "platinum" }
        if Double(paceSeconds) <= interpolated(gold) { return "gold" }
        if Double(paceSeconds) <= interpolated(silver) { return "silver" }
        if Double(paceSeconds) <= interpolated(bronze) { return "bronze" }
        return "none"
    }
}

struct CommunityFriendResponse: Decodable, Equatable, Hashable, Identifiable {
    let userId: Int
    let nickname: String
    let badgeTier: String
    let friendCount: Int
    let profileImageURL: String?
    let status: String

    var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case badgeTier = "badge_tier"
        case friendCount = "friend_count"
        case profileImageURL = "profile_image_url"
        case status
    }
}

struct CommunityFriendActionRequest: Encodable, Equatable, Hashable {
    let targetId: Int
    let action: String

    enum CodingKeys: String, CodingKey {
        case targetId = "target_id"
        case action
    }
}

struct CommunityUserProfileResponse: Decodable, Equatable, Hashable {
    let nickname: String
    let profilePhoto: String?
    let statusMessage: String?
    let friendCount: Int
    let postCount: Int
    let taggedCount: Int
    let commentedFeedCount: Int
    let likedFeedCount: Int
    let bookmarkedFeedCount: Int

    enum CodingKeys: String, CodingKey {
        case nickname = "community_profile_name"
        case profilePhoto = "profile_photo"
        case statusMessage = "status_message"
        case friendCount = "friend_count"
        case postCount = "post_count"
        case taggedCount = "tagged_count"
        case commentedFeedCount = "commented_feed_count"
        case likedFeedCount = "liked_feed_count"
        case bookmarkedFeedCount = "bookmarked_feed_count"
    }

    init(
        nickname: String,
        profilePhoto: String? = nil,
        statusMessage: String? = nil,
        friendCount: Int = 0,
        postCount: Int = 0,
        taggedCount: Int = 0,
        commentedFeedCount: Int = 0,
        likedFeedCount: Int = 0,
        bookmarkedFeedCount: Int = 0
    ) {
        self.nickname = nickname
        self.profilePhoto = profilePhoto
        self.statusMessage = statusMessage
        self.friendCount = friendCount
        self.postCount = postCount
        self.taggedCount = taggedCount
        self.commentedFeedCount = commentedFeedCount
        self.likedFeedCount = likedFeedCount
        self.bookmarkedFeedCount = bookmarkedFeedCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? "Neo Runner"
        profilePhoto = try container.decodeIfPresent(String.self, forKey: .profilePhoto)
        statusMessage = try container.decodeIfPresent(String.self, forKey: .statusMessage)
        friendCount = try container.decodeIfPresent(Int.self, forKey: .friendCount) ?? 0
        postCount = try container.decodeIfPresent(Int.self, forKey: .postCount) ?? 0
        taggedCount = try container.decodeIfPresent(Int.self, forKey: .taggedCount) ?? 0
        commentedFeedCount = try container.decodeIfPresent(Int.self, forKey: .commentedFeedCount) ?? 0
        likedFeedCount = try container.decodeIfPresent(Int.self, forKey: .likedFeedCount) ?? 0
        bookmarkedFeedCount = try container.decodeIfPresent(Int.self, forKey: .bookmarkedFeedCount) ?? 0
    }

    static let sample = CommunityUserProfileResponse(
        nickname: "RunningLover",
        statusMessage: "오늘도 달리는 중",
        friendCount: 999,
        postCount: 12,
        taggedCount: 3,
        commentedFeedCount: 8,
        likedFeedCount: 21,
        bookmarkedFeedCount: 5
    )
}

struct CommunityContentResponse: Decodable, Equatable, Hashable, Identifiable {
    let contentId: Int
    let contentText: String
    let totalDistance: Double
    let duration: Int
    let pace: Int
    let createdAt: String

    var id: Int { contentId }

    enum CodingKeys: String, CodingKey {
        case contentId = "content_id"
        case contentText = "content_text"
        case totalDistance = "total_distance"
        case duration
        case pace
        case createdAt = "created_at"
    }

    static let samples: [CommunityContentResponse] = [
        CommunityContentResponse(contentId: 1, contentText: "오운완", totalDistance: 11.8, duration: 2269, pace: 384, createdAt: "2026-05-11T09:00:00"),
        CommunityContentResponse(contentId: 2, contentText: "단대 코스 좋네요", totalDistance: 5.9, duration: 1690, pace: 286, createdAt: "2026-05-10T20:30:00")
    ]

    init(contentId: Int, contentText: String, totalDistance: Double, duration: Int, pace: Int, createdAt: String) {
        self.contentId = contentId
        self.contentText = contentText
        self.totalDistance = totalDistance
        self.duration = duration
        self.pace = pace
        self.createdAt = createdAt
    }
}

struct CommunityBadgeDetailResponse: Decodable, Equatable, Hashable {
    let tier: String
    let recordId: Int
    let distance: Double
    let pace: String
    let achievedAt: String?

    enum CodingKeys: String, CodingKey {
        case tier = "Badge"
        case recordId = "record_id"
        case distance
        case pace
        case achievedAt = "achieved_at"
    }

    var badgeTier: CommunityBadgeTier {
        CommunityBadgeTier(rawValue: tier.lowercased()) ?? .none
    }

    static let sample = CommunityBadgeDetailResponse(tier: "gold", recordId: 42, distance: 10.0, pace: "6:00/km", achievedAt: "2026-05-11")

    init(tier: String, recordId: Int, distance: Double, pace: String, achievedAt: String?) {
        self.tier = tier
        self.recordId = recordId
        self.distance = distance
        self.pace = pace
        self.achievedAt = achievedAt
    }
}

struct CommunityFeedUploadRequest: Encodable, Equatable, Hashable {
    let title: String
    let content: String
    let privacy: String
    let mapVisible: Bool
    let routeMapImageURI: String?
    let taggedUserIds: [Int]
    let imageURLs: [String]
    let distance: Double
    let runningTime: String
    let pace: String
    let tagCount: Int

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case privacy
        case mapVisible
        case routeMapImageURI = "routeMapImageUri"
        case taggedUserIds
        case imageURLs = "imageUrls"
        case distance
        case runningTime
        case pace
        case tagCount
    }
}

extension CommunityFeedUploadRequest {
    init(
        title: String,
        content: String,
        privacy: CommunityFeedPrivacy,
        mapVisible: Bool,
        routeMapImageURI: String?,
        taggedUsers: [CommunityTagUser],
        imageURLs: [String],
        distance: Double,
        runningTime: String,
        pace: String
    ) {
        self.init(
            title: title,
            content: content,
            privacy: privacy.rawValue,
            mapVisible: mapVisible,
            routeMapImageURI: routeMapImageURI,
            taggedUserIds: taggedUsers.map(\.userId),
            imageURLs: imageURLs,
            distance: distance,
            runningTime: runningTime,
            pace: pace,
            tagCount: taggedUsers.count
        )
    }
}

struct CommunityFeedUploadResponse: Decodable, Equatable, Hashable, Identifiable {
    let feedId: Int
    let profileImageURL: String?
    let nickname: String
    let createdAt: String
    let title: String
    let content: String
    let taggedCount: Int
    let likeCount: Int
    let commentCount: Int
    let distance: String
    let duration: String
    let pace: String
    let mapVisible: Bool
    let routeMapImageURI: String?
    let imageURLs: [String]

    var id: Int { feedId }

    enum CodingKeys: String, CodingKey {
        case feedId
        case profileImageURL = "profileImageUrl"
        case nickname
        case createdAt
        case title
        case content
        case taggedCount
        case likeCount
        case commentCount
        case distance
        case duration
        case pace
        case mapVisible
        case routeMapImageURI = "routeMapImageUri"
        case imageURLs = "imageUrls"
    }

    init(
        feedId: Int,
        profileImageURL: String? = nil,
        nickname: String,
        createdAt: String,
        title: String,
        content: String,
        taggedCount: Int,
        likeCount: Int,
        commentCount: Int,
        distance: String,
        duration: String,
        pace: String,
        mapVisible: Bool,
        routeMapImageURI: String?,
        imageURLs: [String]
    ) {
        self.feedId = feedId
        self.profileImageURL = profileImageURL
        self.nickname = nickname
        self.createdAt = createdAt
        self.title = title
        self.content = content
        self.taggedCount = taggedCount
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.distance = distance
        self.duration = duration
        self.pace = pace
        self.mapVisible = mapVisible
        self.routeMapImageURI = routeMapImageURI
        self.imageURLs = imageURLs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        feedId = try container.decodeIfPresent(Int.self, forKey: .feedId) ?? 0
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? "Neo Runner"
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        taggedCount = try container.decodeIfPresent(Int.self, forKey: .taggedCount) ?? 0
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        distance = try container.decodeIfPresent(String.self, forKey: .distance) ?? ""
        duration = try container.decodeIfPresent(String.self, forKey: .duration) ?? ""
        pace = try container.decodeIfPresent(String.self, forKey: .pace) ?? ""
        mapVisible = try container.decodeIfPresent(Bool.self, forKey: .mapVisible) ?? true
        routeMapImageURI = try container.decodeIfPresent(String.self, forKey: .routeMapImageURI)
        imageURLs = try container.decodeIfPresent([String].self, forKey: .imageURLs) ?? []
    }
}

struct CommunityFriendSummary: Identifiable, Equatable, Hashable {
    let id: Int
    let nickname: String
    let badgeTier: String
    let friendCount: Int
    let status: CommunityFriendStatus

    static let samples: [CommunityFriendSummary] = [
        CommunityFriendSummary(id: 1, nickname: "RunningLover", badgeTier: "gold", friendCount: 999, status: .friends),
        CommunityFriendSummary(id: 2, nickname: "walkingphobia", badgeTier: "silver", friendCount: 999, status: .received),
        CommunityFriendSummary(id: 3, nickname: "CrazyRun", badgeTier: "diamond", friendCount: 999, status: .sent),
        CommunityFriendSummary(id: 4, nickname: "UngCheon1004", badgeTier: "bronze", friendCount: 5, status: .received),
        CommunityFriendSummary(id: 5, nickname: "YoonHyeon7942", badgeTier: "platinum", friendCount: 7, status: .friends)
    ]
}
