import Foundation
import SwiftUI
import WatchConnectivity

@main
struct Neo_Stride_iosApp: App {
    @StateObject private var sessionState = SessionState(
        authStore: KeychainAuthStore(),
        config: .default
    )

    init() {
        WatchWorkoutInbox.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionState)
        }
    }
}

final class WatchWorkoutInbox: NSObject, WCSessionDelegate {
    static let shared = WatchWorkoutInbox()

    private let store: WatchWorkoutStore

    private init(store: WatchWorkoutStore = .shared) {
        self.store = store
        super.init()
    }

    func start() {
        guard WCSession.isSupported(), WCSession.default.delegate == nil else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        persist(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        persist(userInfo)
    }

    private func persist(_ payload: [String: Any]) {
        guard let summary = WatchWorkoutPendingSummary(payload: payload) else { return }
        do {
            try store.upsert(summary)
        } catch {
            NSLog("Failed to persist watch workout summary: \(error.localizedDescription)")
        }
    }
}
