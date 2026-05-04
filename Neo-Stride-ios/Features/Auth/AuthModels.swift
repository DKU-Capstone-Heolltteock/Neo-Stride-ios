import Foundation

struct LoginRequest: Encodable, Equatable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable, Equatable {
    let status: String
    let message: String
    let userId: Int
    let email: String
    let name: String
    let nickname: String?
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case userId = "user_id"
        case email
        case name
        case nickname
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }

    var session: AuthSession {
        AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            nickname: nickname,
            name: name
        )
    }
}

struct SignupRequest: Encodable, Equatable {
    let email: String
    let name: String
    let password: String
}

struct SignupResponse: Decodable, Equatable {
    let status: String
    let message: String
    let userId: Int
    let email: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case userId = "user_id"
        case email
        case name
    }
}
