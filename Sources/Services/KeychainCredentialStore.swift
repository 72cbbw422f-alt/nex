import Foundation
import Security

/// Stores provider passwords in the platform Keychain.
/// Server URLs and usernames are stored separately as non-secret profile metadata.
struct KeychainCredentialStore {
    static let shared = KeychainCredentialStore()
    private let service = "com.nexusstream.provider-credentials"

    enum StoreError: Error {
        case encodingFailed
        case keychainStatus(OSStatus)
    }

    func save(password: String, provider: ConnectionProvider, baseURL: URL, username: String) throws {
        guard let data = password.data(using: .utf8) else { throw StoreError.encodingFailed }
        let query = baseQuery(provider: provider, baseURL: baseURL, username: username)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else { throw StoreError.keychainStatus(updateStatus) }

        var insertQuery = query
        attributes.forEach { insertQuery[$0.key] = $0.value }
        let insertStatus = SecItemAdd(insertQuery as CFDictionary, nil)
        guard insertStatus == errSecSuccess else { throw StoreError.keychainStatus(insertStatus) }
    }

    func password(provider: ConnectionProvider, baseURL: URL, username: String) throws -> String? {
        var query = baseQuery(provider: provider, baseURL: baseURL, username: username)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw StoreError.keychainStatus(status) }
        guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
            throw StoreError.encodingFailed
        }
        return value
    }

    func delete(provider: ConnectionProvider, baseURL: URL, username: String) throws {
        let status = SecItemDelete(baseQuery(provider: provider, baseURL: baseURL, username: username) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw StoreError.keychainStatus(status)
        }
    }

    private func baseQuery(provider: ConnectionProvider, baseURL: URL, username: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accountKey(provider: provider, baseURL: baseURL, username: username)
        ]
    }

    private func accountKey(provider: ConnectionProvider, baseURL: URL, username: String) -> String {
        let server = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        return "\(provider.rawValue.lowercased()):\(server):\(username)"
    }
}
