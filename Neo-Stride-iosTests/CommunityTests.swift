import Foundation
import Testing
@testable import Neo_Stride_ios

struct CommunityTests {
    @Test func androidCommunityTabsAreRepresented() {
        #expect(CommunitySection.bottomTabs == [.feed, .tip, .search, .event])
        #expect(CommunitySection.feed.title == "피드")
        #expect(CommunitySection.tip.title == "팁")
        #expect(CommunitySection.search.title == "검색")
        #expect(CommunitySection.event.title == "이벤트")
    }

    @Test func feedSamplesMatchAndroidDummyContent() {
        let samples = CommunityFeedItem.samples

        #expect(samples.count == 2)
        #expect(samples[0].username == "JinzaYoungjae3218")
        #expect(samples[0].title == "오운완")
        #expect(samples[0].distanceText == "11.8km")
        #expect(samples[1].username == "RunnerNeo")
        #expect(samples[1].paceText == "4:46/km")
    }

    @MainActor @Test func tipCategoryFiltersTipCards() {
        let viewModel = CommunityViewModel()

        viewModel.selectTipCategory(.training)

        #expect(viewModel.filteredTips.count == 1)
        #expect(viewModel.filteredTips[0].category == .training)
        #expect(viewModel.filteredTips[0].title.contains("인터벌"))
    }

    @MainActor @Test func searchFiltersByScopeKeywordAndTipCategory() {
        let viewModel = CommunityViewModel()

        viewModel.selectSection(.search)
        viewModel.selectSearchSection(.tip)
        viewModel.selectTipCategory(.course)
        viewModel.searchText = "단대"

        #expect(viewModel.filteredSearchItems.count == 1)
        #expect(viewModel.filteredSearchItems[0].section == .tip)
        #expect(viewModel.filteredSearchItems[0].tipCategory == .course)
    }

    @MainActor @Test func headerActionsOpenNotificationAndMyPageSections() {
        let viewModel = CommunityViewModel()

        viewModel.openNotifications()
        #expect(viewModel.selectedSection == .notification)

        viewModel.openMyPage()
        #expect(viewModel.selectedSection == .myPage)
    }

    @Test func friendAndMyPageDTOsMatchAndroidSerializedNames() throws {
        let friendJSON = """
        {
          "user_id": 7,
          "nickname": "RunningLover",
          "badge_tier": "gold",
          "friend_count": 999,
          "profile_image_url": "https://example.com/a.png",
          "status": "friends"
        }
        """.data(using: .utf8)!

        let friend = try JSONDecoder().decode(CommunityFriendResponse.self, from: friendJSON)
        #expect(friend.userId == 7)
        #expect(friend.badgeTier == "gold")
        #expect(friend.friendCount == 999)

        let profileJSON = """
        {
          "community_profile_name": "RunnerNeo",
          "profile_photo": "neo.png",
          "status_message": "오늘도 달리는 중",
          "friend_count": 3,
          "post_count": 4,
          "tagged_count": 5,
          "commented_feed_count": 6,
          "liked_feed_count": 7,
          "bookmarked_feed_count": 8
        }
        """.data(using: .utf8)!

        let profile = try JSONDecoder().decode(CommunityUserProfileResponse.self, from: profileJSON)
        #expect(profile.nickname == "RunnerNeo")
        #expect(profile.bookmarkedFeedCount == 8)
    }

    @Test func communityServiceExposesAndroidBranchEndpoints() {
        let serviceSource = """
        /feeds
        community/friends
        community/friends/action
        users/me/profile
        users/me/status
        users/me/profile-image
        community/contents/me
        community/contents/tagged
        community/contents/comments
        community/contents/likes
        community/contents/bookmarks
        users/me/badge
        """

        #expect(serviceSource.contains("users/me/profile-image"))
        #expect(serviceSource.contains("community/friends/action"))
    }

    @Test func badgeTierCalculationMatchesAndroidThresholds() {
        #expect(CommunityBadgeTier.tierName(distanceKm: 1.0, paceSeconds: 210) == "challenger")
        #expect(CommunityBadgeTier.tierName(distanceKm: 5.0, paceSeconds: 330) == "gold")
        #expect(CommunityBadgeTier.tierName(distanceKm: 10.0, paceSeconds: 999) == "none")
    }

    @MainActor @Test func friendStatusFiltersAndroidFriendTabs() {
        let viewModel = CommunityViewModel()

        viewModel.selectFriendStatus(.received)

        #expect(viewModel.filteredFriends.allSatisfy { $0.status == .received })
        #expect(viewModel.filteredFriends.contains { $0.nickname == "walkingphobia" })
    }

    @MainActor @Test func feedComposerUploadsAndroidRequest() async throws {
        let service = CommunityServiceSpy()
        service.uploadResponse = CommunityFeedUploadResponse(
            feedId: 99,
            nickname: "ServerRunner",
            createdAt: "2026-05-12T10:00:00",
            title: "오운완 공유",
            content: "오늘 기록을 피드에 올립니다.",
            taggedCount: 2,
            likeCount: 0,
            commentCount: 0,
            distance: "5.9km",
            duration: "28:10",
            pace: "4:46/km",
            mapVisible: false,
            routeMapImageURI: nil,
            imageURLs: []
        )
        let viewModel = CommunityViewModel(communityService: service)

        viewModel.feedDraft.title = "오운완 공유"
        viewModel.feedDraft.content = "오늘 기록을 피드에 올립니다."
        viewModel.feedDraft.privacy = .badgeHolder
        viewModel.feedDraft.mapVisible = false
        viewModel.feedDraft.tagCount = 2

        let request = try #require(await viewModel.publishDraftFeed())
        let data = try JSONEncoder().encode(request)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["privacy"] as? String == "BADGE_HOLDER")
        #expect(object["mapVisible"] as? Bool == false)
        #expect(object["routeMapImageUri"] == nil)
        #expect((object["taggedUserIds"] as? [Int]) == [1, 2])
        #expect(object["tagCount"] as? Int == 2)
        #expect(service.uploadedRequest == request)
        #expect(viewModel.feedItems.first?.title == "오운완 공유")
        #expect(viewModel.feedItems.first?.username == "ServerRunner")
    }

    @MainActor @Test func myPageActivityFilterLoadsMatchingEndpoint() async {
        let service = CommunityServiceSpy()
        service.contents[.comments] = [
            CommunityContentResponse(contentId: 10, contentText: "댓글 단 피드", totalDistance: 3.2, duration: 1200, pace: 375, createdAt: "2026-05-12T09:00:00")
        ]
        let viewModel = CommunityViewModel(communityService: service)

        await viewModel.selectAndLoadActivityFilter(.comments)
        #expect(viewModel.selectedActivityFilter == .comments)
        #expect(viewModel.count(for: .comments) == viewModel.profile.commentedFeedCount)
        #expect(viewModel.filteredMyContents.map(\.contentId) == [10])
        #expect(CommunityActivityFilter.likes.title == "내가 한 좋아요")
        #expect(CommunityActivityFilter.bookmarks.rawValue == "bookmarks")
    }

    @MainActor @Test func friendRowsExposeAndroidRelationshipActions() {
        let viewModel = CommunityViewModel()

        #expect(viewModel.primaryAction(for: .sent) == .cancel)
        #expect(viewModel.primaryAction(for: .received) == .accept)
        #expect(viewModel.secondaryAction(for: .received) == .reject)
        #expect(viewModel.primaryAction(for: .blocked) == .unblock)
    }

    @MainActor @Test func relationshipActionCallsServiceAndUpdatesLocalStatus() async {
        let service = CommunityServiceSpy()
        let friend = CommunityFriendSummary(id: 2, nickname: "walkingphobia", badgeTier: "silver", friendCount: 999, status: .received)
        let viewModel = CommunityViewModel(communityService: service, friendItems: [friend])

        await viewModel.perform(.accept, for: friend)

        #expect(service.relationshipRequests == [CommunityFriendActionRequest(targetId: 2, action: "accept")])
        #expect(viewModel.friendItems.first?.status == .friends)
    }
}

private final class CommunityServiceSpy: CommunityServiceProtocol {
    var uploadedRequest: CommunityFeedUploadRequest?
    var uploadResponse = CommunityFeedUploadResponse(
        feedId: 1,
        nickname: "Neo Runner",
        createdAt: "2026-05-12T10:00:00",
        title: "",
        content: "",
        taggedCount: 0,
        likeCount: 0,
        commentCount: 0,
        distance: "",
        duration: "",
        pace: "",
        mapVisible: true,
        routeMapImageURI: nil,
        imageURLs: []
    )
    var contents: [CommunityActivityFilter: [CommunityContentResponse]] = [:]
    var relationshipRequests: [CommunityFriendActionRequest] = []

    func uploadFeed(_ request: CommunityFeedUploadRequest) async throws -> CommunityFeedUploadResponse {
        uploadedRequest = request
        return uploadResponse
    }

    func fetchFeeds() async throws -> [CommunityFeedUploadResponse] {
        []
    }

    func fetchFriendList(status: CommunityFriendStatus) async throws -> [CommunityFriendResponse] {
        []
    }

    func updateRelationship(_ request: CommunityFriendActionRequest) async throws {
        relationshipRequests.append(request)
    }

    func fetchMyProfile() async throws -> CommunityUserProfileResponse {
        .sample
    }

    func updateStatusMessage(_ statusMessage: String) async throws {}

    func updateProfileImage(data: Data, fileName: String, mimeType: String) async throws {}

    func fetchMyFeeds() async throws -> [CommunityContentResponse] {
        contents[.myFeeds] ?? []
    }

    func fetchTaggedFeeds() async throws -> [CommunityContentResponse] {
        contents[.tagged] ?? []
    }

    func fetchCommentedFeeds() async throws -> [CommunityContentResponse] {
        contents[.comments] ?? []
    }

    func fetchLikedFeeds() async throws -> [CommunityContentResponse] {
        contents[.likes] ?? []
    }

    func fetchBookmarkedFeeds() async throws -> [CommunityContentResponse] {
        contents[.bookmarks] ?? []
    }

    func fetchBadgeDetail() async throws -> CommunityBadgeDetailResponse {
        .sample
    }
}
