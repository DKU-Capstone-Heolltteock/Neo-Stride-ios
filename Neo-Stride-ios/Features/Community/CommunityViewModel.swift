import Combine
import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var selectedSection: CommunitySection = .feed
    @Published var selectedTipCategory: CommunityTipCategory = .all
    @Published var searchSection: CommunitySection = .feed
    @Published var searchText: String = ""
    @Published var selectedFriendStatus: CommunityFriendStatus = .friends
    @Published var profile: CommunityUserProfileResponse
    @Published var badge: CommunityBadgeDetailResponse
    @Published var selectedActivityFilter: CommunityActivityFilter = .myFeeds
    @Published var isFeedComposerPresented = false
    @Published var isStatusEditorPresented = false
    @Published var feedDraft = FeedDraft()
    @Published var isPublishingFeed = false
    @Published var isLoadingActivity = false
    @Published var relationshipErrorMessage: String?
    @Published var editedStatusMessage = ""

    @Published private(set) var feedItems: [CommunityFeedItem]
    let tipItems: [CommunityTipItem]
    let searchItems: [CommunitySearchItem]
    @Published private(set) var friendItems: [CommunityFriendSummary]
    @Published private var myContentsByFilter: [CommunityActivityFilter: [CommunityContentResponse]]
    private let communityService: CommunityServiceProtocol?

    struct FeedDraft: Equatable {
        var title = ""
        var content = ""
        var privacy: CommunityFeedPrivacy = .friend
        var mapVisible = true
        var tagCount = 0
        var errorMessage: String?

        func makeUploadRequest() throws -> CommunityFeedUploadRequest {
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedTitle.isEmpty else {
                throw ValidationError.missingTitle
            }

            guard !trimmedContent.isEmpty else {
                throw ValidationError.missingContent
            }

            let taggedUsers = (0..<tagCount).map {
                CommunityTagUser(userId: $0 + 1, nickname: "TaggedRunner\($0 + 1)")
            }

            return CommunityFeedUploadRequest(
                title: trimmedTitle,
                content: trimmedContent,
                privacy: privacy,
                mapVisible: mapVisible,
                routeMapImageURI: mapVisible ? "neostride://route/latest" : nil,
                taggedUsers: taggedUsers,
                imageURLs: [],
                distance: 5.9,
                runningTime: "28:10",
                pace: "4:46/km"
            )
        }

        enum ValidationError: LocalizedError {
            case missingTitle
            case missingContent

            var errorDescription: String? {
                switch self {
                case .missingTitle:
                    return "제목을 입력해주세요."
                case .missingContent:
                    return "내용을 입력해주세요."
                }
            }
        }
    }

    init(
        communityService: CommunityServiceProtocol? = nil,
        feedItems: [CommunityFeedItem]? = nil,
        tipItems: [CommunityTipItem]? = nil,
        searchItems: [CommunitySearchItem]? = nil,
        friendItems: [CommunityFriendSummary]? = nil,
        myContents: [CommunityContentResponse]? = nil,
        profile: CommunityUserProfileResponse? = nil,
        badge: CommunityBadgeDetailResponse? = nil
    ) {
        self.communityService = communityService
        self.feedItems = feedItems ?? CommunityFeedItem.samples
        self.tipItems = tipItems ?? CommunityTipItem.samples
        self.searchItems = searchItems ?? CommunitySearchItem.samples
        self.friendItems = friendItems ?? CommunityFriendSummary.samples
        self.myContentsByFilter = [.myFeeds: myContents ?? CommunityContentResponse.samples]
        self.profile = profile ?? .sample
        self.badge = badge ?? .sample
    }

    var filteredTips: [CommunityTipItem] {
        guard selectedTipCategory != .all else { return tipItems }
        return tipItems.filter { $0.category == selectedTipCategory }
    }

    var filteredSearchItems: [CommunitySearchItem] {
        let normalizedKeyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return searchItems.filter { item in
            let matchesSection = item.section == mappedSearchSection
            let matchesKeyword = normalizedKeyword.isEmpty
                || item.title.lowercased().contains(normalizedKeyword)
                || item.subtitle.lowercased().contains(normalizedKeyword)
            let matchesTipCategory = mappedSearchSection != .tip
                || selectedTipCategory == .all
                || item.tipCategory == selectedTipCategory
            return matchesSection && matchesKeyword && matchesTipCategory
        }
    }

    var mappedSearchSection: CommunitySection {
        switch searchSection {
        case .feed: return .feed
        case .tip: return .tip
        case .myPage: return .myPage
        case .notification: return .notification
        case .search, .event: return searchSection
        }
    }

    var filteredFriends: [CommunityFriendSummary] {
        friendItems.filter { $0.status == selectedFriendStatus }
    }

    var filteredMyContents: [CommunityContentResponse] {
        myContentsByFilter[selectedActivityFilter] ?? []
    }

    var myPageCounters: [(String, Int)] {
        [
            ("친구", profile.friendCount),
            ("내 피드", profile.postCount),
            ("태그", profile.taggedCount),
            ("댓글", profile.commentedFeedCount),
            ("좋아요", profile.likedFeedCount),
            ("북마크", profile.bookmarkedFeedCount)
        ]
    }

    func count(for filter: CommunityActivityFilter) -> Int {
        profile.count(for: filter)
    }

    func selectSection(_ section: CommunitySection) {
        selectedSection = section
        if section.isBottomTab {
            searchSection = section == .search ? .feed : section
        }
    }

    func openNotifications() {
        selectedSection = .notification
    }

    func openMyPage() {
        selectedSection = .myPage
    }

    func selectTipCategory(_ category: CommunityTipCategory) {
        selectedTipCategory = category
    }

    func selectSearchSection(_ section: CommunitySection) {
        searchSection = section
    }

    func selectFriendStatus(_ status: CommunityFriendStatus) {
        selectedFriendStatus = status
    }

    func selectActivityFilter(_ filter: CommunityActivityFilter) {
        selectedActivityFilter = filter
    }

    func selectAndLoadActivityFilter(_ filter: CommunityActivityFilter) async {
        selectedActivityFilter = filter
        await loadActivityFilter(filter)
    }

    func loadSelectedActivityFilter() async {
        await loadActivityFilter(selectedActivityFilter)
    }

    private func loadActivityFilter(_ filter: CommunityActivityFilter) async {
        guard myContentsByFilter[filter] == nil else { return }
        guard let communityService else {
            myContentsByFilter[filter] = []
            return
        }

        isLoadingActivity = true
        do {
            myContentsByFilter[filter] = try await filter.fetchContents(using: communityService)
        } catch {
            myContentsByFilter[filter] = []
        }
        isLoadingActivity = false
    }

    func beginFeedCompose() {
        feedDraft = FeedDraft()
        isFeedComposerPresented = true
    }

    @discardableResult
    func publishDraftFeed() async -> CommunityFeedUploadRequest? {
        feedDraft.errorMessage = nil
        let request: CommunityFeedUploadRequest
        do {
            request = try feedDraft.makeUploadRequest()
        } catch {
            feedDraft.errorMessage = error.localizedDescription
            return nil
        }

        isPublishingFeed = true
        defer { isPublishingFeed = false }

        do {
            if let communityService {
                let response = try await communityService.uploadFeed(request)
                insertFeed(CommunityFeedItem(uploadResponse: response))
            } else {
                insertFeed(CommunityFeedItem(uploadRequest: request, username: profile.nickname))
            }
            isFeedComposerPresented = false
        } catch {
            feedDraft.errorMessage = "피드 업로드 실패"
            return nil
        }

        return request
    }

    func beginStatusEdit() {
        editedStatusMessage = profile.statusMessage ?? ""
        isStatusEditorPresented = true
    }

    func saveEditedStatusMessage() {
        profile = CommunityUserProfileResponse(
            nickname: profile.nickname,
            profilePhoto: profile.profilePhoto,
            statusMessage: editedStatusMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            friendCount: profile.friendCount,
            postCount: profile.postCount,
            taggedCount: profile.taggedCount,
            commentedFeedCount: profile.commentedFeedCount,
            likedFeedCount: profile.likedFeedCount,
            bookmarkedFeedCount: profile.bookmarkedFeedCount
        )
        isStatusEditorPresented = false
    }

    func primaryAction(for status: CommunityFriendStatus) -> CommunityFriendAction? {
        switch status {
        case .friends: return .block
        case .sent: return .cancel
        case .received: return .accept
        case .blocked: return .unblock
        }
    }

    func secondaryAction(for status: CommunityFriendStatus) -> CommunityFriendAction? {
        status == .received ? .reject : nil
    }

    func perform(_ action: CommunityFriendAction, for friend: CommunityFriendSummary) async {
        relationshipErrorMessage = nil

        do {
            if let communityService {
                try await communityService.updateRelationship(
                    CommunityFriendActionRequest(targetId: friend.id, action: action.rawValue)
                )
            }
            apply(action, to: friend)
        } catch {
            relationshipErrorMessage = "친구 관계 변경 실패"
        }
    }

    private func insertFeed(_ item: CommunityFeedItem) {
        feedItems.insert(item, at: 0)
    }

    private func apply(_ action: CommunityFriendAction, to friend: CommunityFriendSummary) {
        switch action {
        case .accept:
            replace(friend, status: .friends)
        case .block:
            replace(friend, status: .blocked)
        case .cancel, .reject, .unblock:
            friendItems.removeAll { $0.id == friend.id }
        }
    }

    private func replace(_ friend: CommunityFriendSummary, status: CommunityFriendStatus) {
        guard let index = friendItems.firstIndex(where: { $0.id == friend.id }) else { return }
        friendItems[index] = friend.withStatus(status)
    }
}

private extension CommunityActivityFilter {
    func fetchContents(using service: CommunityServiceProtocol) async throws -> [CommunityContentResponse] {
        switch self {
        case .myFeeds:
            return try await service.fetchMyFeeds()
        case .tagged:
            return try await service.fetchTaggedFeeds()
        case .comments:
            return try await service.fetchCommentedFeeds()
        case .likes:
            return try await service.fetchLikedFeeds()
        case .bookmarks:
            return try await service.fetchBookmarkedFeeds()
        }
    }
}

private extension CommunityUserProfileResponse {
    func count(for filter: CommunityActivityFilter) -> Int {
        switch filter {
        case .myFeeds:
            return postCount
        case .tagged:
            return taggedCount
        case .comments:
            return commentedFeedCount
        case .likes:
            return likedFeedCount
        case .bookmarks:
            return bookmarkedFeedCount
        }
    }
}

private extension CommunityFriendSummary {
    func withStatus(_ status: CommunityFriendStatus) -> CommunityFriendSummary {
        CommunityFriendSummary(
            id: id,
            nickname: nickname,
            badgeTier: badgeTier,
            friendCount: friendCount,
            status: status
        )
    }
}
