import Foundation
import Security

final class KeychainAuthStore: AuthStore {
    private let service = "com.neostride.ios.auth"
    private let sessionKey = "authSession"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var session: AuthSession? {
        guard let data = readData(sessionKey) else { return nil }
        return try? decoder.decode(AuthSession.self, from: data)
    }

    var accessToken: String? { session?.accessToken }
    var refreshToken: String? { session?.refreshToken }
    var userId: Int? { session?.userId }
    var nickname: String? { session?.nickname }
    var name: String? { session?.name }

    func save(session: AuthSession) {
        do {
            let data = try encoder.encode(session)
            let status = write(data, key: sessionKey)
            assert(status == errSecSuccess, "Failed to persist auth session in Keychain: \(status)")
        } catch {
            assertionFailure("Failed to encode auth session: \(error.localizedDescription)")
        }
    }

    func clear() {
        delete(sessionKey)
    }

    private func readData(_ key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    @discardableResult
    private func write(_ data: Data, key: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return updateStatus
        }
        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            return SecItemAdd(addQuery as CFDictionary, nil)
        }
        return updateStatus
    }

    private func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
