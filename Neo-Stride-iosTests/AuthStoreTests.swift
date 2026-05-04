import Testing
@testable import Neo_Stride_ios

struct AuthStoreTests {
    @Test func inMemoryAuthStoreSavesSessionAndClearsIt() throws {
        let store = InMemoryAuthStore()
        let session = AuthSession(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            userId: 42,
            nickname: "runner",
            name: "홍길동"
        )

        store.save(session: session)

        #expect(store.accessToken == "access-token")
        #expect(store.refreshToken == "refresh-token")
        #expect(store.userId == 42)
        #expect(store.nickname == "runner")
        #expect(store.name == "홍길동")

        store.clear()

        #expect(store.accessToken == nil)
        #expect(store.refreshToken == nil)
        #expect(store.userId == nil)
        #expect(store.nickname == nil)
        #expect(store.name == nil)
    }
}
