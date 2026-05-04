import SwiftUI

struct RootView: View {
    @EnvironmentObject private var sessionState: SessionState

    var body: some View {
        Group {
            if sessionState.isAuthenticated {
                MainTabView()
            } else {
                LoginView(viewModel: AuthViewModel(
                    authService: AuthService(apiClient: APIClient(config: sessionState.config, authStore: sessionState)),
                    sessionState: sessionState
                ))
            }
        }
        .preferredColorScheme(.dark)
    }
}
