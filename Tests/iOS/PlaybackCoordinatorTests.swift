import XCTest
@testable import NEXUS_iOS

@MainActor
final class PlaybackCoordinatorTests: XCTestCase {
    func testStartLoadsURLThenStartsPlayback() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)
        let url = URL(string: "https://media.example/live/channel.m3u8")!

        coordinator.start(url: url)

        XCTAssertEqual(engine.loadedURL, url)
        XCTAssertEqual(engine.calls, ["load", "play"])
    }

    func testPauseAndResumeAreForwardedToEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)

        coordinator.pause()
        coordinator.resume()

        XCTAssertEqual(engine.calls, ["pause", "play"])
    }

    func testSeekIsForwardedToEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)

        coordinator.seek(to: 123.5)

        XCTAssertEqual(engine.lastSeek, 123.5, accuracy: 0.001)
        XCTAssertEqual(engine.calls, ["seek"])
    }

    func testPlaybackStateIsReadFromEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)

        engine.currentTime = 45
        engine.isPlaying = true

        XCTAssertEqual(coordinator.currentTime, 45)
        XCTAssertTrue(coordinator.isPlaying)
    }
}

@MainActor
private final class FakePlaybackEngine: PlaybackEngine {
    var currentTime: TimeInterval = 0
    var isPlaying = false
    var loadedURL: URL?
    var lastSeek: TimeInterval = 0
    var calls: [String] = []

    func load(_ url: URL) {
        loadedURL = url
        calls.append("load")
    }

    func play() {
        isPlaying = true
        calls.append("play")
    }

    func pause() {
        isPlaying = false
        calls.append("pause")
    }

    func seek(to seconds: TimeInterval) {
        lastSeek = seconds
        currentTime = seconds
        calls.append("seek")
    }
}
