import XCTest
@testable import NEXUS_iOS

final class SubtitleServiceTests: XCTestCase {
    func testRecognizesOnlySupportedSubtitleExtensions() {
        XCTAssertEqual(SubtitleFormat(fileExtension: "SRT"), .srt)
        XCTAssertEqual(SubtitleFormat(fileExtension: "vtt"), .webVTT)
        XCTAssertNil(SubtitleFormat(fileExtension: "ass"))
    }

    func testRanksPreferredLanguageBeforeOtherLanguages() {
        let query = SubtitleSearchQuery(tmdbID: 550, mediaKind: .movie)
        let english = candidate(id: "en", language: "en", tmdbID: 550)
        let swedish = candidate(id: "sv", language: "sv", tmdbID: 550)

        let ranked = SubtitleMatching.rank(
            [english, swedish],
            for: query,
            preferences: SubtitlePreferences(preferredLanguageCodes: ["sv", "en"])
        )

        XCTAssertEqual(ranked.map(\.id), ["sv", "en"])
    }

    func testRejectsWrongMovieAndWrongEpisodeMatches() {
        let movieQuery = SubtitleSearchQuery(tmdbID: 550, mediaKind: .movie)
        let wrongMovie = candidate(id: "wrong", language: "sv", tmdbID: 551)
        XCTAssertTrue(SubtitleMatching.rank([wrongMovie], for: movieQuery, preferences: .init()).isEmpty)

        let episodeQuery = SubtitleSearchQuery(
            tmdbID: 1399,
            mediaKind: .series,
            seasonNumber: 2,
            episodeNumber: 4
        )
        let wrongEpisode = candidate(
            id: "wrong-episode",
            language: "sv",
            tmdbID: 1399,
            mediaKind: .series,
            season: 2,
            episode: 3
        )
        XCTAssertTrue(SubtitleMatching.rank([wrongEpisode], for: episodeQuery, preferences: .init()).isEmpty)
    }

    func testExactFileHashRanksAboveReleaseNameMatch() {
        let query = SubtitleSearchQuery(
            tmdbID: 550,
            mediaKind: .movie,
            releaseName: "Example.Release",
            fileHash: "ABC123"
        )
        let releaseMatch = candidate(id: "release", language: "sv", tmdbID: 550, release: "Example.Release")
        let hashMatch = candidate(id: "hash", language: "sv", tmdbID: 550, hash: "abc123")

        let ranked = SubtitleMatching.rank(
            [releaseMatch, hashMatch],
            for: query,
            preferences: .init(preferredLanguageCodes: ["sv"])
        )

        XCTAssertEqual(ranked.first?.id, "hash")
    }

    private func candidate(
        id: String,
        language: String,
        tmdbID: Int,
        mediaKind: SubtitleMediaKind = .movie,
        season: Int? = nil,
        episode: Int? = nil,
        release: String? = nil,
        hash: String? = nil
    ) -> SubtitleCandidate {
        SubtitleCandidate(
            id: id,
            providerID: "test-provider",
            languageCode: language,
            format: .srt,
            tmdbID: tmdbID,
            mediaKind: mediaKind,
            seasonNumber: season,
            episodeNumber: episode,
            releaseName: release,
            fileHash: hash,
            downloadURL: URL(string: "https://subtitles.example/\(id).srt")!
        )
    }
}
