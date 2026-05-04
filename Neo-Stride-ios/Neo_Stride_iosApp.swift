import SwiftUI

@main
struct Neo_Stride_iosApp: App {
    @StateObject private var sessionState = SessionState(
        authStore: KeychainAuthStore(),
        config: .default
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionState)
        }
    }
}
