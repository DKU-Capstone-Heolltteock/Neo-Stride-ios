import Combine
import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var selectedSection: CommunitySection = .feed
    @Published var selectedTipCategory: CommunityTipCategory = .all
    @Published var searchSection: CommunitySection = .feed
    @Published var searchText: String = ""

    let feedItems: [CommunityFeedItem]
    let tipItems: [CommunityTipItem]
    let searchItems: [CommunitySearchItem]

    init(
        feedItems: [CommunityFeedItem] = CommunityFeedItem.samples,
        tipItems: [CommunityTipItem] = CommunityTipItem.samples,
        searchItems: [CommunitySearchItem] = CommunitySearchItem.samples
    ) {
        self.feedItems = feedItems
        self.tipItems = tipItems
        self.searchItems = searchItems
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
}
