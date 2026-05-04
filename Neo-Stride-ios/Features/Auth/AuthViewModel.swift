import Combine
import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var keepLogin = true
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let authService: AuthService
    private weak var sessionState: SessionState?

    init(authService: AuthService, sessionState: SessionState?) {
        self.authService = authService
        self.sessionState = sessionState
    }

    func login() async {
        await login(email: email, password: password, keepLogin: keepLogin)
    }

    func login(email: String, password: String, keepLogin: Bool) async {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "이메일을 입력하세요."
            return
        }
        guard !password.isEmpty else {
            errorMessage = "비밀번호를 입력하세요."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await authService.login(email: trimmedEmail, password: password)
            sessionState?.save(session: response.session, persist: keepLogin)
        } catch APIError.unauthorized {
            errorMessage = "이메일 또는 비밀번호가 올바르지 않습니다."
        } catch APIError.serverError(let statusCode, _) where statusCode == 400 {
            errorMessage = "입력값을 확인해주세요."
        } catch {
            errorMessage = "서버 연결 실패"
        }
    }

    func signup() async -> Bool {
        await signup(email: email, name: name, password: password)
    }

    func signup(email: String, name: String, password: String) async -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            errorMessage = "이메일을 입력하세요."
            return false
        }
        guard !trimmedName.isEmpty else {
            errorMessage = "이름을 입력하세요."
            return false
        }
        guard !password.isEmpty else {
            errorMessage = "비밀번호를 입력하세요."
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await authService.signup(email: trimmedEmail, name: trimmedName, password: password)
            return true
        } catch APIError.serverError(let statusCode, _) where statusCode == 409 {
            errorMessage = "이미 가입된 이메일입니다."
            return false
        } catch APIError.serverError(let statusCode, _) where statusCode == 400 {
            errorMessage = "입력값을 확인해주세요."
            return false
        } catch {
            errorMessage = "서버 연결 실패"
            return false
        }
    }

    func logout() {
        sessionState?.logout()
    }
}
