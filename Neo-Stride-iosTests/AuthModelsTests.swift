import Foundation
import Testing
@testable import Neo_Stride_ios

struct AuthModelsTests {
    @Test func loginResponseDecodesSnakeCaseTokensAndUserID() throws {
        let json = """
        {
          "status": "success",
          "message": "로그인에 성공했습니다.",
          "user_id": 1,
          "email": "runner@example.com",
          "name": "홍길동",
          "nickname": "홍길동",
          "access_token": "access-token",
          "refresh_token": "refresh-token"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(LoginResponse.self, from: json)

        #expect(response.userId == 1)
        #expect(response.accessToken == "access-token")
        #expect(response.refreshToken == "refresh-token")
        #expect(response.nickname == "홍길동")
    }

    @Test func signupResponseDecodesUserID() throws {
        let json = """
        {
          "status": "success",
          "message": "회원가입이 완료되었습니다.",
          "user_id": 7,
          "email": "runner@example.com",
          "name": "홍길동"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(SignupResponse.self, from: json)

        #expect(response.userId == 7)
        #expect(response.email == "runner@example.com")
    }
}
