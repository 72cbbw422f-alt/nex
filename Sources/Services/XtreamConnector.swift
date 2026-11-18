import Foundation

struct XtreamConnector: ProviderConnector, Sendable {
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

    func shortEPG(configuration: ProviderConnectionConfiguration, credentials: ProviderCredentials, streamID: Int, limit: Int = 10) async throws -> [XtreamEPGProgram] {
        let payload = try await request(
            configuration: configuration,
            credentials: credentials,
            action: "get_short_epg",
            extra: ["stream_id": String(streamID), "limit": String(max(1, min(limit, 50)))]
        )
        guard let root = payload as? [String: Any],
              let listings = root["epg_listings"],
              let data = try? JSONSerialization.data(withJSONObject: listings) else {
            throw ConnectionError.invalidResponse
        }
        do { return try JSONDecoder().decode([XtreamEPGProgram].self, from: data) }
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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            guard Self.isTransientNetworkError(error) else { throw error }
            try await Self.waitBeforeRetry()
            (data, response) = try await session.data(for: request)
        }

        guard let http = response as? HTTPURLResponse else { throw ConnectionError.nonHTTPResponse }
        if (500...599).contains(http.statusCode) {
            try await Self.waitBeforeRetry()
            let (retryData, retryResponse) = try await session.data(for: request)
            guard let retryHTTP = retryResponse as? HTTPURLResponse else { throw ConnectionError.nonHTTPResponse }
            guard (200..<300).contains(retryHTTP.statusCode) else { throw ConnectionError.serverRejected(retryHTTP.statusCode) }
            do { return try JSONSerialization.jsonObject(with: retryData) }
            catch { throw ConnectionError.invalidResponse }
        }
        guard (200..<300).contains(http.statusCode) else { throw ConnectionError.serverRejected(http.statusCode) }
        do { return try JSONSerialization.jsonObject(with: data) }
        catch { throw ConnectionError.invalidResponse }
    }

    private static func isTransientNetworkError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
             .dnsLookupFailed, .notConnectedToInternet, .resourceUnavailable:
            return true
        default:
            return false
        }
    }

    private static func waitBeforeRetry() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}


/// Shares one in-flight EPG request between the timeline and channel detail panel.
actor XtreamEPGRequestCoordinator {
    static let shared = XtreamEPGRequestCoordinator()

    private var inFlight: [String: Task<[XtreamEPGProgram], Error>] = [:]

    func programs(
        for key: String,
        operation: @escaping @Sendable () async throws -> [XtreamEPGProgram]
    ) async throws -> [XtreamEPGProgram] {
        if let existing = inFlight[key] {
            return try await existing.value
        }

        let task = Task { try await operation() }
        inFlight[key] = task
        defer { inFlight[key] = nil }
        return try await task.value
    }
}

struct XtreamLiveCategory: Decodable, Identifiable, Equatable, Sendable {
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

struct XtreamLiveStream: Decodable, Identifiable, Equatable, Sendable {
    let name: String
    let streamID: Int
    let streamIcon: URL?
    let epgChannelID: String?
    let categoryID: String?
    let streamType: String?
    let containerExtension: String?

    var id: Int { streamID }

    enum CodingKeys: String, CodingKey {
        case name
        case streamID = "stream_id"
        case streamIcon = "stream_icon"
        case epgChannelID = "epg_channel_id"
        case categoryID = "category_id"
        case streamType = "stream_type"
        case containerExtension = "container_extension"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        streamID = try container.decode(Int.self, forKey: .streamID)
        let iconValue = try container.decodeIfPresent(String.self, forKey: .streamIcon)
        streamIcon = iconValue.flatMap(URL.init(string:))
        epgChannelID = try container.decodeIfPresent(String.self, forKey: .epgChannelID)
        categoryID = try container.decodeIfPresent(String.self, forKey: .categoryID)
        streamType = try container.decodeIfPresent(String.self, forKey: .streamType)
        containerExtension = try container.decodeIfPresent(String.self, forKey: .containerExtension)
    }
}


/// Constructs a playback URL only when the provider supplies a recognized container extension.
enum XtreamPlaybackLocator {
    enum LocatorError: LocalizedError {
        case invalidExtension
        case invalidURL

        var errorDescription: String? {
            switch self {
            case .invalidExtension: return "Leverantören har inte angett ett giltigt videoformat för kanalen."
            case .invalidURL: return "Kunde inte skapa en giltig uppspelningsadress."
            }
        }
    }

    static func liveStreamURL(
        baseURL: URL,
        username: String,
        password: String,
        streamID: Int,
        containerExtension: String?
    ) throws -> URL {
        guard let rawExtension = containerExtension?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawExtension.isEmpty,
              rawExtension.range(of: #"^[A-Za-z0-9]{2,8}$"#, options: .regularExpression) != nil else {
            throw LocatorError.invalidExtension
        }

        guard !username.isEmpty, !password.isEmpty, streamID > 0,
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host != nil else {
            throw LocatorError.invalidURL
        }
        // RFC 3986 unreserved ASCII only. Unicode CharacterSet.alphanumerics can
        // leave non-ASCII credentials unescaped in a percent-encoded path.
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        func encodeSegment(_ value: String) throws -> String {
            guard let encoded = value.addingPercentEncoding(withAllowedCharacters: allowed) else {
                throw LocatorError.invalidURL
            }
            return encoded
        }

        let basePath = components.percentEncodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let segments = try ["live", username, password, "\(streamID).\(rawExtension.lowercased())"].map(encodeSegment)
        let path = ([basePath].filter { !$0.isEmpty } + segments).joined(separator: "/")
        components.percentEncodedPath = "/" + path
        components.query = nil
        components.fragment = nil
        guard let finalURL = components.url else { throw LocatorError.invalidURL }
        return finalURL
    }
}


struct XtreamEPGProgram: Decodable, Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let description: String
    let startTimestamp: Date?
    let endTimestamp: Date?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case description = "description"
        case startTimestamp = "start_timestamp"
        case endTimestamp = "stop_timestamp"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = Self.decodeBase64(try container.decodeIfPresent(String.self, forKey: .title)) ?? "Okänt program"
        description = Self.decodeBase64(try container.decodeIfPresent(String.self, forKey: .description)) ?? ""
        startTimestamp = Self.decodeTimestamp(from: container, forKey: .startTimestamp)
        endTimestamp = Self.decodeTimestamp(from: container, forKey: .endTimestamp)

        if let stringID = try? container.decode(String.self, forKey: .id), !stringID.isEmpty {
            id = stringID
        } else if let numericID = try? container.decode(Int64.self, forKey: .id) {
            id = String(numericID)
        } else {
            // Stable fallback: repeated decoding of the same listing must not create a new identity.
            let start = startTimestamp?.timeIntervalSince1970 ?? 0
            let end = endTimestamp?.timeIntervalSince1970 ?? 0
            id = "\(Int64(start))|\(Int64(end))|\(title)"
        }
    }

    private static func decodeBase64(_ value: String?) -> String? {
        guard let value, let data = Data(base64Encoded: value) else { return value }
        return String(data: data, encoding: .utf8) ?? value
    }

    private static func decodeTimestamp(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Date? {
        if let seconds = try? container.decode(Double.self, forKey: key) {
            return Date(timeIntervalSince1970: seconds)
        }
        if let integerSeconds = try? container.decode(Int64.self, forKey: key) {
            return Date(timeIntervalSince1970: TimeInterval(integerSeconds))
        }
        if let string = try? container.decode(String.self, forKey: key),
           let seconds = TimeInterval(string) {
            return Date(timeIntervalSince1970: seconds)
        }
        return nil
    }
}
