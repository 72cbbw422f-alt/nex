import Foundation

enum SubtitleFormat: String, Equatable, Sendable {
    case srt
    case webVTT = "vtt"

    init?(fileExtension: String) {
        switch fileExtension.lowercased() {
        case "srt": self = .srt
        case "vtt", "webvtt": self = .webVTT
        default: return nil
        }
    }

    var fileExtension: String { rawValue }
}

enum SubtitleMediaKind: String, Equatable, Sendable {
    case movie
    case series
}

struct SubtitleSearchQuery: Equatable, Sendable {
    let tmdbID: Int?
    let mediaKind: SubtitleMediaKind
    let seasonNumber: Int?
    let episodeNumber: Int?
    let releaseName: String?
    let fileHash: String?

    init(
        tmdbID: Int?,
        mediaKind: SubtitleMediaKind,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        releaseName: String? = nil,
        fileHash: String? = nil
    ) {
        self.tmdbID = tmdbID
        self.mediaKind = mediaKind
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.releaseName = releaseName
        self.fileHash = fileHash
    }
}

struct SubtitleCandidate: Identifiable, Equatable, Sendable {
    let id: String
    let providerID: String
    let languageCode: String
    let format: SubtitleFormat
    let tmdbID: Int?
    let mediaKind: SubtitleMediaKind
    let seasonNumber: Int?
    let episodeNumber: Int?
    let releaseName: String?
    let fileHash: String?
    let downloadURL: URL
}

struct SubtitleAsset: Identifiable, Equatable, Sendable {
    let id: String
    let localURL: URL
    let format: SubtitleFormat
    let languageCode: String
    let sourceName: String
    let checksum: String?
    let downloadedAt: Date
}

struct SubtitlePreferences: Equatable, Sendable {
    /// Ordered ISO language codes, for example ["sv", "en"].
    var preferredLanguageCodes: [String]
    var preferEmbeddedTracks: Bool
    var syncOffset: TimeInterval

    init(
        preferredLanguageCodes: [String] = ["sv", "en"],
        preferEmbeddedTracks: Bool = true,
        syncOffset: TimeInterval = 0
    ) {
        self.preferredLanguageCodes = preferredLanguageCodes.map { $0.lowercased() }
        self.preferEmbeddedTracks = preferEmbeddedTracks
        self.syncOffset = syncOffset.isFinite ? syncOffset : 0
    }
}

/// Provider adapters implement search and download; credentials and HTTP details stay outside the domain layer.
protocol SubtitleService: Sendable {
    func search(for query: SubtitleSearchQuery) async throws -> [SubtitleCandidate]
    func download(_ candidate: SubtitleCandidate) async throws -> SubtitleAsset
}

enum SubtitleMatching {
    /// Returns only candidates with compatible media identity, ordered by language preference and match confidence.
    static func rank(
        _ candidates: [SubtitleCandidate],
        for query: SubtitleSearchQuery,
        preferences: SubtitlePreferences
    ) -> [SubtitleCandidate] {
        let hasStableIdentifier = query.tmdbID != nil
            || !(query.fileHash?.isEmpty ?? true)
            || !(query.releaseName?.isEmpty ?? true)
        guard hasStableIdentifier else { return [] }

        return candidates
            .filter { candidate in
                guard candidate.mediaKind == query.mediaKind else { return false }
                if let expectedID = query.tmdbID, candidate.tmdbID != expectedID { return false }
                if query.tmdbID == nil {
                    let hashMatches = !(query.fileHash?.isEmpty ?? true)
                        && candidate.fileHash?.caseInsensitiveCompare(query.fileHash ?? "") == .orderedSame
                    let releaseMatches = !(query.releaseName?.isEmpty ?? true)
                        && candidate.releaseName?.localizedCaseInsensitiveCompare(query.releaseName ?? "") == .orderedSame
                    guard hashMatches || releaseMatches else { return false }
                }
                if query.mediaKind == .series {
                    guard candidate.seasonNumber == query.seasonNumber,
                          candidate.episodeNumber == query.episodeNumber else { return false }
                }
                return true
            }
            .sorted { lhs, rhs in
                let leftLanguage = languageRank(lhs.languageCode, preferences: preferences)
                let rightLanguage = languageRank(rhs.languageCode, preferences: preferences)
                if leftLanguage != rightLanguage { return leftLanguage < rightLanguage }

                let leftConfidence = confidence(lhs, query: query)
                let rightConfidence = confidence(rhs, query: query)
                if leftConfidence != rightConfidence { return leftConfidence > rightConfidence }
                return lhs.id < rhs.id
            }
    }

    private static func languageRank(_ code: String, preferences: SubtitlePreferences) -> Int {
        preferences.preferredLanguageCodes.firstIndex(of: code.lowercased()) ?? Int.max
    }

    private static func confidence(_ candidate: SubtitleCandidate, query: SubtitleSearchQuery) -> Int {
        var score = 0
        if let hash = query.fileHash, !hash.isEmpty, candidate.fileHash?.caseInsensitiveCompare(hash) == .orderedSame {
            score += 4
        }
        if let release = query.releaseName, !release.isEmpty,
           candidate.releaseName?.localizedCaseInsensitiveCompare(release) == .orderedSame {
            score += 2
        }
        if let id = query.tmdbID, candidate.tmdbID == id { score += 1 }
        return score
    }
}
