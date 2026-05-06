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
}
