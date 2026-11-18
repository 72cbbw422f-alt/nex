import XCTest
@testable import NEXUS_iOS

final class XtreamPlaybackLocatorTests: XCTestCase {
    func testBuildsLiveURLAndPreservesBasePath() throws {
        let url = try XtreamPlaybackLocator.liveStreamURL(
            baseURL: URL(string: "https://provider.example:8443/portal/")!,
            username: "viewer",
            password: "secret",
            streamID: 42,
            containerExtension: "TS"
        )

        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "provider.example")
        XCTAssertEqual(components.port, 8443)
        XCTAssertEqual(components.percentEncodedPath, "/portal/live/viewer/secret/42.ts")
        XCTAssertNil(components.query)
        XCTAssertNil(components.fragment)
    }

    func testEncodesReservedAndUnicodeCredentialCharactersAsPathSegments() throws {
        let url = try XtreamPlaybackLocator.liveStreamURL(
            baseURL: URL(string: "https://provider.example")!,
            username: "å+user",
            password: "p@ss/word?#%",
            streamID: 7,
            containerExtension: "m3u8"
        )

        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertTrue(components.percentEncodedPath.contains("%C3%A5%2Buser"))
        XCTAssertTrue(components.percentEncodedPath.contains("p%40ss%2Fword%3F%23%25"))
        XCTAssertEqual(components.path, "/live/å+user/p@ss/word?#%/7.m3u8")
    }

    func testRejectsMissingOrMalformedExtension() {
        for value in [nil, "", "../ts", "m3u8?x=1", "this-extension-is-too-long"] {
            XCTAssertThrowsError(
                try XtreamPlaybackLocator.liveStreamURL(
                    baseURL: URL(string: "https://provider.example")!,
                    username: "viewer",
                    password: "secret",
                    streamID: 7,
                    containerExtension: value
                )
            )
        }
    }

    func testRejectsInvalidBaseURLAndCredentials() {
        let invalidCases: [(URL, String, String, Int)] = [
            (URL(string: "file:///tmp/provider")!, "viewer", "secret", 7),
            (URL(string: "https://provider.example")!, "", "secret", 7),
            (URL(string: "https://provider.example")!, "viewer", "", 7),
            (URL(string: "https://provider.example")!, "viewer", "secret", 0)
        ]

        for item in invalidCases {
            XCTAssertThrowsError(
                try XtreamPlaybackLocator.liveStreamURL(
                    baseURL: item.0,
                    username: item.1,
                    password: item.2,
                    streamID: item.3,
                    containerExtension: "ts"
                )
            )
        }
    }
}
