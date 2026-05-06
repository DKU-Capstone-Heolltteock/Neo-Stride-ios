import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel: CommunityViewModel

    init(viewModel: CommunityViewModel = CommunityViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                Group {
                    switch viewModel.selectedSection {
                    case .feed:
                        feedContent
                    case .tip:
                        tipContent
                    case .search:
                        searchContent
                    case .event:
                        placeholderContent(
                            icon: "gift",
                            title: "이벤트",
                            message: "커뮤니티 이벤트는 Android와 동일하게 화면 틀부터 준비했습니다."
                        )
                    case .notification:
                        placeholderContent(
                            icon: "bell",
                            title: "알림",
                            message: "새 댓글, 좋아요, 친구 요청 알림이 이곳에 표시됩니다."
                        )
                    case .myPage:
                        placeholderContent(
                            icon: "person.crop.circle",
                            title: "마이페이지",
                            message: "프로필, 내가 쓴 글, 친구 목록 화면으로 확장할 자리입니다."
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                communityTabBar
            }
            .background(NeoStrideColors.background.ignoresSafeArea())
            .navigationTitle("커뮤니티")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Label("Neo Community", systemImage: "person.3.fill")
                .font(.headline)
                .foregroundStyle(NeoStrideColors.primaryText)

            Spacer()

            Button {
                viewModel.openNotifications()
            } label: {
                Image(systemName: "bell")
                    .font(.headline)
                    .foregroundStyle(viewModel.selectedSection == .notification ? NeoStrideColors.accent : NeoStrideColors.primaryText)
            }
            .accessibilityLabel("알림")

            Button {
                viewModel.openMyPage()
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title3)
                    .foregroundStyle(viewModel.selectedSection == .myPage ? NeoStrideColors.accent : NeoStrideColors.primaryText)
            }
            .accessibilityLabel("마이페이지")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(NeoStrideColors.surface)
    }

    private var feedContent: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                HStack {
                    Text("러너 피드")
                        .font(.title2.bold())
                        .foregroundStyle(NeoStrideColors.primaryText)
                    Spacer()
                    Button {
                    } label: {
                        Label("글쓰기", systemImage: "square.and.pencil")
                            .font(.subheadline.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(NeoStrideColors.accent)
                    .foregroundStyle(NeoStrideColors.background)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                ForEach(viewModel.feedItems) { item in
                    FeedCard(item: item)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 20)
        }
    }

    private var tipContent: some View {
        VStack(spacing: 0) {
            tipCategoryPicker

            ScrollView {
                LazyVStack(spacing: 12) {
                    HStack {
                        Text("러닝 팁")
                            .font(.title2.bold())
                            .foregroundStyle(NeoStrideColors.primaryText)
                        Spacer()
                        Button {
                        } label: {
                            Label("작성", systemImage: "plus")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.bordered)
                        .tint(NeoStrideColors.accent)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                    ForEach(viewModel.filteredTips) { item in
                        TipCard(item: item)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private var searchContent: some View {
        VStack(spacing: 14) {
            TextField("커뮤니티 검색", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(NeoStrideColors.surface)
                .foregroundStyle(NeoStrideColors.primaryText)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
                .padding(.top, 16)

            searchScopePicker

            if viewModel.searchSection == .tip {
                tipCategoryPicker
            }

            if viewModel.filteredSearchItems.isEmpty {
                placeholderContent(
                    icon: "magnifyingglass",
                    title: "검색 결과 없음",
                    message: "다른 키워드나 카테고리를 선택해보세요."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredSearchItems) { item in
                            SearchResultRow(item: item)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private var tipCategoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CommunityTipCategory.allCases) { category in
                    Button {
                        viewModel.selectTipCategory(category)
                    } label: {
                        Text(category.title)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(viewModel.selectedTipCategory == category ? NeoStrideColors.background : NeoStrideColors.primaryText)
                            .background(viewModel.selectedTipCategory == category ? NeoStrideColors.accent : NeoStrideColors.surface)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var searchScopePicker: some View {
        HStack(spacing: 8) {
            searchScopeButton(.feed, title: "피드")
            searchScopeButton(.tip, title: "팁")
            searchScopeButton(.myPage, title: "프로필")
            searchScopeButton(.notification, title: "친구")
        }
        .padding(.horizontal, 20)
    }

    private func searchScopeButton(_ section: CommunitySection, title: String) -> some View {
        Button {
            viewModel.selectSearchSection(section)
        } label: {
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                Rectangle()
                    .fill(viewModel.searchSection == section ? NeoStrideColors.accent : Color.clear)
                    .frame(height: 2)
            }
            .foregroundStyle(viewModel.searchSection == section ? NeoStrideColors.accent : NeoStrideColors.primaryText)
            .frame(maxWidth: .infinity)
        }
    }

    private var communityTabBar: some View {
        HStack(spacing: 0) {
            ForEach(CommunitySection.bottomTabs) { section in
                Button {
                    viewModel.selectSection(section)
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: section.systemImage)
                        Text(section.title)
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(viewModel.selectedSection == section ? NeoStrideColors.accent : NeoStrideColors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(NeoStrideColors.surface)
    }

    private func placeholderContent(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(NeoStrideColors.accent)
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(NeoStrideColors.primaryText)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(NeoStrideColors.secondaryText)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct FeedCard: View {
    let item: CommunityFeedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(NeoStrideColors.accent)
                    .frame(width: 34, height: 34)
                    .overlay(Text(String(item.username.prefix(1))).font(.caption.bold()).foregroundStyle(NeoStrideColors.background))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.username)
                        .font(.subheadline.bold())
                        .foregroundStyle(NeoStrideColors.primaryText)
                    Text(item.timeText)
                        .font(.caption)
                        .foregroundStyle(NeoStrideColors.secondaryText)
                }
                Spacer()
                Label("\(item.tagCount)", systemImage: "tag")
                    .font(.caption)
                    .foregroundStyle(NeoStrideColors.secondaryText)
            }

            Text(item.title)
                .font(.title3.bold())
                .foregroundStyle(NeoStrideColors.primaryText)

            HStack(spacing: 10) {
                metric(title: "거리", value: item.distanceText)
                metric(title: "시간", value: item.durationText)
                metric(title: "페이스", value: item.paceText)
            }

            HStack(spacing: 18) {
                Label("\(item.likeCount)", systemImage: "heart")
                Label("\(item.commentCount)", systemImage: "bubble.right")
                Spacer()
                Image(systemName: "map")
            }
            .font(.caption.bold())
            .foregroundStyle(NeoStrideColors.secondaryText)
        }
        .padding(16)
        .background(NeoStrideColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(NeoStrideColors.secondaryText)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(NeoStrideColors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(NeoStrideColors.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TipCard: View {
    let item: CommunityTipItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.category.title)
                    .font(.caption.bold())
                    .foregroundStyle(NeoStrideColors.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NeoStrideColors.accent)
                    .clipShape(Capsule())
                Spacer()
                Text(item.author)
                    .font(.caption)
                    .foregroundStyle(NeoStrideColors.secondaryText)
            }

            Text(item.title)
                .font(.headline)
                .foregroundStyle(NeoStrideColors.primaryText)
            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(NeoStrideColors.secondaryText)
        }
        .padding(16)
        .background(NeoStrideColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct SearchResultRow: View {
    let item: CommunitySearchItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.section.systemImage)
                .foregroundStyle(NeoStrideColors.accent)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(NeoStrideColors.primaryText)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(NeoStrideColors.secondaryText)
            }
            Spacer()
        }
        .padding(14)
        .background(NeoStrideColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
