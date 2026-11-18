import Foundation

enum ConnectionProvider: String, CaseIterable, Identifiable, Equatable, Codable {
    case xtream = "Xtream"
    case jellyfin = "Jellyfin"

    var id: String { rawValue }
    var symbol: String { self == .xtream ? "antenna.radiowaves.left.and.right" : "server.rack" }
    var description: String {
        self == .xtream
            ? "IPTV-kanaler, filmer, serier och EPG från din leverantör."
            : "Bibliotek, metadata och tillgängliga strömmar från din Jellyfin-server."
    }
}

struct ProviderConnectionConfiguration: Equatable {
    let provider: ConnectionProvider
    let baseURL: URL
    let username: String
}

struct ProviderCredentials {
    let password: String
}

/// Non-secret connection metadata. Passwords are deliberately excluded.
struct SavedProviderConnection: Identifiable, Codable, Equatable {
    let id: UUID
    let provider: ConnectionProvider
    let baseURL: URL
    let username: String
    let createdAt: Date

    init(id: UUID = UUID(), provider: ConnectionProvider, baseURL: URL, username: String, createdAt: Date = .now) {
        self.id = id
        self.provider = provider
        self.baseURL = baseURL
        self.username = username
        self.createdAt = createdAt
    }

    var displayName: String {
        URLComponents(url: baseURL, resolvingAgainstBaseURL: false)?.host ?? baseURL.absoluteString
    }
}

/// Persists only non-secret profile metadata. Credentials remain in Keychain.
struct ProviderConnectionStore {
    static let shared = ProviderConnectionStore()
    private let storageKey = "nexus.saved-provider-connections"

    func load() -> [SavedProviderConnection] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let values = try? JSONDecoder().decode([SavedProviderConnection].self, from: data) else {
            return []
        }
        return values
    }

    func save(_ connection: SavedProviderConnection) throws {
        var values = load()
        if let index = values.firstIndex(where: { $0.id == connection.id }) {
            values[index] = connection
        } else {
            values.append(connection)
        }
        try persist(values)
    }

    func delete(id: UUID) throws {
        try persist(load().filter { $0.id != id })
    }

    private func persist(_ values: [SavedProviderConnection]) throws {
        let data = try JSONEncoder().encode(values)
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

/// Validates only the local shape of the supplied values. It does not contact a server.
enum ProviderConnectionValidator {
    enum ValidationError: LocalizedError {
        case invalidAddress
        case missingUsername
        case missingPassword

        var errorDescription: String? {
            switch self {
            case .invalidAddress:
                return "Ange en giltig serveradress som börjar med http:// eller https://."
            case .missingUsername:
                return "Ange användarnamn."
            case .missingPassword:
                return "Ange lösenord."
            }
        }
    }

    static func validate(
        provider: ConnectionProvider,
        address: String,
        username: String,
        password: String
    ) throws -> (configuration: ProviderConnectionConfiguration, credentials: ProviderCredentials) {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            let components = URLComponents(string: trimmedAddress),
            let scheme = components.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            let host = components.host,
            !host.isEmpty,
            components.user == nil,
            components.password == nil,
            let url = components.url
        else {
            throw ValidationError.invalidAddress
        }

        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanUsername.isEmpty else { throw ValidationError.missingUsername }
        guard !password.isEmpty else { throw ValidationError.missingPassword }

        return (
            ProviderConnectionConfiguration(provider: provider, baseURL: url, username: cleanUsername),
            ProviderCredentials(password: password)
        )
    }
}

/// Provider adapters implement this after their API contract and authentication flow are verified.
protocol ProviderConnector {
    var provider: ConnectionProvider { get }
    func testConnection(configuration: ProviderConnectionConfiguration, credentials: ProviderCredentials) async throws
}
