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

struct CommunityFeedItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let username: String
    let timeText: String
    let title: String
    let tagCount: Int
    let likeCount: Int
    let commentCount: Int
    let distanceText: String
    let durationText: String
    let paceText: String

    init(
        id: UUID = UUID(),
        username: String,
        timeText: String,
        title: String,
        tagCount: Int,
        likeCount: Int,
        commentCount: Int,
        distanceText: String,
        durationText: String,
        paceText: String
    ) {
        self.id = id
        self.username = username
        self.timeText = timeText
        self.title = title
        self.tagCount = tagCount
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.distanceText = distanceText
        self.durationText = durationText
        self.paceText = paceText
    }

    static let samples: [CommunityFeedItem] = [
        CommunityFeedItem(
            username: "JinzaYoungjae3218",
            timeText: "7분 전",
            title: "오운완",
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
            tagCount: 5,
            likeCount: 12,
            commentCount: 4,
            distanceText: "5.9km",
            durationText: "28:10",
            paceText: "4:46/km"
        )
    ]
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
