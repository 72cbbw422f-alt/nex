import Foundation

struct XtreamConnector: ProviderConnector {
    let provider: ConnectionProvider = .xtream
    private let session: URLSession

    enum ConnectionError: LocalizedError {
        case invalidProvider
        case invalidEndpoint
        case nonHTTPResponse
        case serverRejected(Int)
        case invalidResponse
        case authenticationFailed
        case accountDisabled

        var errorDescription: String? {
            switch self {
            case .invalidProvider: return "Den här anslutningen är inte en Xtream-profil."
            case .invalidEndpoint: return "Kunde inte skapa en giltig Xtream API-adress."
            case .nonHTTPResponse: return "Servern svarade inte med ett giltigt HTTP-svar."
            case .serverRejected(let code): return "Servern svarade med HTTP \(code)."
            case .invalidResponse: return "Servern returnerade ett svar som inte känns igen som Xtream-inloggning."
            case .authenticationFailed: return "Inloggningen misslyckades. Kontrollera serveradress, användarnamn och lösenord."
            case .accountDisabled: return "Kontot är inte aktivt eller har spärrats av leverantören."
            }
        }
    }

    init(session: URLSession = .shared) {
        self.session = session
    }

    func testConnection(configuration: ProviderConnectionConfiguration, credentials: ProviderCredentials) async throws {
        guard configuration.provider == .xtream else { throw ConnectionError.invalidProvider }
        let payload = try await request(configuration: configuration, credentials: credentials, action: nil)
        guard
            let root = payload as? [String: Any],
            let userInfo = root["user_info"] as? [String: Any],
            let authValue = userInfo["auth"] as? NSNumber
        else {
            throw ConnectionError.invalidResponse
        }

        guard authValue.intValue == 1 else { throw ConnectionError.authenticationFailed }
        if let status = userInfo["status"] as? String,
           !["Active", "Enabled", "active", "enabled"].contains(status) {
            throw ConnectionError.accountDisabled
        }
    }

    func liveCategories(configuration: ProviderConnectionConfiguration, credentials: ProviderCredentials) async throws -> [XtreamLiveCategory] {
        let payload = try await request(configuration: configuration, credentials: credentials, action: "get_live_categories")
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { throw ConnectionError.invalidResponse }
        do { return try JSONDecoder().decode([XtreamLiveCategory].self, from: data) }
        catch { throw ConnectionError.invalidResponse }
    }

    func liveStreams(configuration: ProviderConnectionConfiguration, credentials: ProviderCredentials, categoryID: String? = nil) async throws -> [XtreamLiveStream] {
        let payload = try await request(configuration: configuration, credentials: credentials, action: "get_live_streams", extra: categoryID.map { ["category_id": $0] } ?? [:])
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { throw ConnectionError.invalidResponse }
        do { return try JSONDecoder().decode([XtreamLiveStream].self, from: data) }
        catch { throw ConnectionError.invalidResponse }
    }

    private func request(
        configuration: ProviderConnectionConfiguration,
        credentials: ProviderCredentials,
        action: String?,
        extra: [String: String] = [:]
    ) async throws -> Any {
        var endpoint = configuration.baseURL
        endpoint.appendPathComponent("player_api.php")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw ConnectionError.invalidEndpoint
        }

        var items = [
            URLQueryItem(name: "username", value: configuration.username),
            URLQueryItem(name: "password", value: credentials.password)
        ]
        if let action { items.append(URLQueryItem(name: "action", value: action)) }
        items.append(contentsOf: extra.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) })
        components.queryItems = items
        guard let url = components.url else { throw ConnectionError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ConnectionError.nonHTTPResponse }
        guard (200..<300).contains(http.statusCode) else { throw ConnectionError.serverRejected(http.statusCode) }
        do { return try JSONSerialization.jsonObject(with: data) }
        catch { throw ConnectionError.invalidResponse }
    }
}

struct XtreamLiveCategory: Decodable, Identifiable, Equatable {
    let categoryID: String
    let categoryName: String
    let parentID: Int?

    var id: String { categoryID }

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case categoryName = "category_name"
        case parentID = "parent_id"
    }
}

struct XtreamLiveStream: Decodable, Identifiable, Equatable {
    let name: String
    let streamID: Int
    let streamIcon: URL?
    let epgChannelID: String?
    let categoryID: String?
    let streamType: String?

    var id: Int { streamID }

    enum CodingKeys: String, CodingKey {
        case name
        case streamID = "stream_id"
        case streamIcon = "stream_icon"
        case epgChannelID = "epg_channel_id"
        case categoryID = "category_id"
        case streamType = "stream_type"
    }
}
