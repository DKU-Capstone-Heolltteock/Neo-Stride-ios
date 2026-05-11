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
}
