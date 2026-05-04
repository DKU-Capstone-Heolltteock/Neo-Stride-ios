import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var sessionState: SessionState

    var body: some View {
        TabView {
            PlaceholderFeatureView(title: "Running", subtitle: "자유 러닝 추적은 다음 단계에서 구현합니다.")
                .tabItem { Label("러닝", systemImage: "figure.run") }

            PlaceholderFeatureView(title: "Record", subtitle: "월별 러닝 기록은 Phase 4에서 구현합니다.")
                .tabItem { Label("기록", systemImage: "calendar") }

            PlaceholderFeatureView(title: "Coaching", subtitle: "서버 기반 코칭 플랜은 Phase 5에서 구현합니다.")
                .tabItem { Label("코칭", systemImage: "sparkles") }

            PlaceholderFeatureView(title: "Community", subtitle: "커뮤니티는 MVP 이후 확장합니다.")
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
