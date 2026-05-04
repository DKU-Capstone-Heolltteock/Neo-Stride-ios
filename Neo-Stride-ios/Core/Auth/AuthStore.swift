import Foundation

struct AuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let userId: Int
    let nickname: String?
    let name: String?

    init(accessToken: String, refreshToken: String, userId: Int, nickname: String?, name: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.nickname = nickname
        self.name = name
    }
}

protocol AuthStore: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }
    var userId: Int? { get }
    var nickname: String? { get }
    var name: String? { get }

    func save(session: AuthSession)
    func clear()
}

final class InMemoryAuthStore: AuthStore {
    private(set) var accessToken: String?
    private(set) var refreshToken: String?
    private(set) var userId: Int?
    private(set) var nickname: String?
    private(set) var name: String?

    func save(session: AuthSession) {
        accessToken = session.accessToken
        refreshToken = session.refreshToken
        userId = session.userId
        nickname = session.nickname
        name = session.name
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        nickname = nil
        name = nil
    }
}
