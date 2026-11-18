import Foundation
import Security

/// Stores provider passwords in the platform Keychain.
/// Never store server URLs, usernames or passwords in UserDefaults.
struct KeychainCredentialStore {
    static let shared = KeychainCredentialStore()

    private let service = "com.nexusstream.provider-credentials"

    enum StoreError: Error {
        case encodingFailed
        case keychainStatus(OSStatus)
    }

    func save(password: String, provider: ConnectionProvider, username: String) throws {
        guard let data = password.data(using: .utf8) else { throw StoreError.encodingFailed }
        let account = accountKey(provider: provider, username: username)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw StoreError.keychainStatus(updateStatus)
        }

        var insertQuery = baseQuery
        attributes.forEach { insertQuery[$0.key] = $0.value }
        let insertStatus = SecItemAdd(insertQuery as CFDictionary, nil)
        guard insertStatus == errSecSuccess else {
            throw StoreError.keychainStatus(insertStatus)
        }
    }

    func password(provider: ConnectionProvider, username: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey(provider: provider, username: username),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw StoreError.keychainStatus(status) }
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw StoreError.encodingFailed
        }
        return value
    }

    func delete(provider: ConnectionProvider, username: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey(provider: provider, username: username)
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StoreError.keychainStatus(status)
        }
    }

    private func accountKey(provider: ConnectionProvider, username: String) -> String {
        "\(provider.rawValue.lowercased()):\(username.lowercased())"
    }
}
