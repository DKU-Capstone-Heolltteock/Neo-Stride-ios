import SwiftUI

@MainActor
final class SessionState: ObservableObject, AuthStore {
    let persistentAuthStore: AuthStore
    let config: AppConfig

    @Published private(set) var isAuthenticated: Bool
    private var transientSession: AuthSession?

    var accessToken: String? { transientSession?.accessToken ?? persistentAuthStore.accessToken }
    var refreshToken: String? { transientSession?.refreshToken ?? persistentAuthStore.refreshToken }
    var userId: Int? { transientSession?.userId ?? persistentAuthStore.userId }
    var nickname: String? { transientSession?.nickname ?? persistentAuthStore.nickname }
    var name: String? { transientSession?.name ?? persistentAuthStore.name }

    init(authStore: AuthStore, config: AppConfig) {
        self.persistentAuthStore = authStore
        self.config = config
        self.isAuthenticated = authStore.accessToken?.isEmpty == false
    }

    func save(session: AuthSession) {
        save(session: session, persist: true)
    }

    func save(session: AuthSession, persist: Bool) {
        if persist {
            persistentAuthStore.save(session: session)
            transientSession = nil
        } else {
            transientSession = session
        }
        isAuthenticated = true
    }

    func markAuthenticated() {
        isAuthenticated = accessToken?.isEmpty == false
    }

    func clear() {
        persistentAuthStore.clear()
        transientSession = nil
        isAuthenticated = false
    }

    func logout() {
        clear()
    }
}

extension SessionState {
    static var previewLoggedOut: SessionState {
        SessionState(authStore: InMemoryAuthStore(), config: .default)
    }
}
