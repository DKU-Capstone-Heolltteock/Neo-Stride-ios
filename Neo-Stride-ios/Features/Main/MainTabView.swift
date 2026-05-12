import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var sessionState: SessionState

    var body: some View {
        TabView {
            RunningView(viewModel: RunningViewModel(
                runningService: RunningService(apiClient: APIClient(config: sessionState.config, authStore: sessionState)),
                authStore: sessionState
            ))
            .tabItem { Label("러닝", systemImage: "figure.run") }

            RecordsView(viewModel: RecordsViewModel(
                recordsService: RecordsService(apiClient: APIClient(config: sessionState.config, authStore: sessionState)),
                authStore: sessionState
            ))
            .tabItem { Label("기록", systemImage: "calendar") }

            CoachingView(viewModel: CoachingViewModel(
                coachingService: CoachingService(apiClient: APIClient(config: sessionState.config, authStore: sessionState)),
                authStore: sessionState
            ))
            .tabItem { Label("코칭", systemImage: "sparkles") }

            CommunityView(viewModel: CommunityViewModel(
                communityService: CommunityService(apiClient: APIClient(config: sessionState.config, authStore: sessionState))
            ))
                .tabItem { Label("커뮤니티", systemImage: "person.3") }
        }
        .tint(NeoStrideColors.accent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("로그아웃") {
                    sessionState.logout()
                }
            }
        }
    }
}

struct PlaceholderFeatureView: View {
    let title: String
    let subtitle: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(NeoStrideColors.primaryText)
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(NeoStrideColors.secondaryText)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NeoStrideColors.background.ignoresSafeArea())
            .navigationTitle(title)
        }
    }
}
