import AVFoundation
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

    func testPlaybackStateChangesAreForwardedFromEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)
        var notificationCount = 0
        coordinator.onStateChanged = { notificationCount += 1 }

        engine.emitStateChange()

        XCTAssertEqual(notificationCount, 1)
    }

    func testTrackChangesAreForwardedFromEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)
        var notificationCount = 0
        coordinator.onTracksChanged = { notificationCount += 1 }

        engine.emitTracksChange()

        XCTAssertEqual(notificationCount, 1)
    }

    func testPauseAndResumeAreForwardedToEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)

        coordinator.pause()
        coordinator.resume()

        XCTAssertEqual(engine.calls, ["pause", "play"])
    }

    func testStopIsForwardedToEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)

        coordinator.stop()

        XCTAssertEqual(engine.calls, ["stop"])
    }

    func testSeekIsForwardedToEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)

        coordinator.seek(to: 123.5)

        XCTAssertEqual(engine.lastSeek, 123.5, accuracy: 0.001)
        XCTAssertEqual(engine.calls, ["seek"])
    }

    func testPlaybackStateAndTracksAreExposedWithoutEngineTypes() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)
        let audio = PlaybackTrack(id: "audio-en", kind: .audio, displayName: "English", languageCode: "en", isSelected: true)
        let subtitles = PlaybackTrack(id: "subtitle-sv", kind: .subtitle, displayName: "Svenska", languageCode: "sv")

        engine.currentTime = 45
        engine.duration = 180
        engine.isSeekable = true
        engine.capabilities = [.seeking, .embeddedAudioSelection, .externalSubtitles]
        engine.isPlaying = true
        engine.audioTracks = [audio]
        engine.subtitleTracks = [subtitles]
        engine.state = .buffering

        XCTAssertEqual(coordinator.currentTime, 45)
        XCTAssertEqual(coordinator.duration, 180)
        XCTAssertTrue(coordinator.isSeekable)
        XCTAssertEqual(coordinator.capabilities, [.seeking, .embeddedAudioSelection, .externalSubtitles])
        XCTAssertTrue(coordinator.isPlaying)
        XCTAssertEqual(coordinator.state, .buffering)
        XCTAssertEqual(coordinator.audioTracks, [audio])
        XCTAssertEqual(coordinator.subtitleTracks, [subtitles])
    }

    func testExternalSubtitleIsRejectedWhenEngineDoesNotAdvertiseSupport() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)
        let url = URL(fileURLWithPath: "/tmp/sample.srt")

        XCTAssertFalse(coordinator.attachExternalSubtitle(from: url, languageCode: "sv"))
        XCTAssertNil(engine.attachedSubtitleURL)
    }

    func testExternalSubtitleIsForwardedWhenEngineAdvertisesSupport() {
        let engine = FakePlaybackEngine()
        engine.capabilities = [.externalSubtitles]
        let coordinator = PlaybackCoordinator(engine: engine)
        let url = URL(fileURLWithPath: "/tmp/sample.srt")

        XCTAssertTrue(coordinator.attachExternalSubtitle(from: url, languageCode: "sv"))
        XCTAssertEqual(engine.attachedSubtitleURL, url)
        XCTAssertEqual(engine.attachedSubtitleLanguage, "sv")
    }

    func testTrackSelectionIsForwardedToEngine() {
        let engine = FakePlaybackEngine()
        let coordinator = PlaybackCoordinator(engine: engine)

        XCTAssertTrue(coordinator.selectAudioTrack(id: "audio-en"))
        XCTAssertTrue(coordinator.selectSubtitleTrack(id: "subtitle-sv"))
        XCTAssertTrue(coordinator.selectSubtitleTrack(id: nil))
        XCTAssertEqual(engine.selectedAudioID, "audio-en")
        XCTAssertEqual(engine.selectedSubtitleIDs, ["subtitle-sv", "off"])
    }

    func testAVPlayerEngineReportsEndedWhenCurrentItemFinishes() async {
        let player = AVPlayer()
        let engine = AVPlayerPlaybackEngine(player: player)
        let finished = expectation(description: "Playback completion is forwarded")
        engine.onStateChanged = {
            if engine.state == .ended {
                finished.fulfill()
            }
        }
        let url = URL(fileURLWithPath: "/tmp/nexus-playback-completion-fixture.mp4")

        engine.load(url)
        guard let item = player.currentItem else {
            XCTFail("Expected the engine to install a current item")
            return
        }

        NotificationCenter.default.post(
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        await fulfillment(of: [finished], timeout: 2)
        XCTAssertEqual(engine.state, .ended)
        engine.stop()
    }

    func testAVPlayerEngineIgnoresCompletionFromReplacedItem() async {
        let player = AVPlayer()
        let engine = AVPlayerPlaybackEngine(player: player)
        let firstURL = URL(fileURLWithPath: "/tmp/nexus-old-fixture.mp4")
        let secondURL = URL(fileURLWithPath: "/tmp/nexus-new-fixture.mp4")

        engine.load(firstURL)
        guard let oldItem = player.currentItem else {
            XCTFail("Expected the first item to be installed")
            return
        }

        engine.load(secondURL)
        guard let currentItem = player.currentItem else {
            XCTFail("Expected the replacement item to be installed")
            return
        }

        NotificationCenter.default.post(
            name: .AVPlayerItemDidPlayToEndTime,
            object: oldItem
        )

        // Allow the notification's MainActor task to run.
        await Task.yield()

        XCTAssertFalse(engine.state == .ended)
        XCTAssertTrue(player.currentItem === currentItem)
        engine.stop()
    }

}

@MainActor
private final class FakePlaybackEngine: PlaybackEngine {
    var currentTime: TimeInterval = 0
    var duration: TimeInterval?
    var isSeekable = false
    var capabilities: PlaybackEngineCapabilities = []
    var isPlaying = false
    var state: PlaybackEngineState = .idle
    var audioTracks: [PlaybackTrack] = []
    var subtitleTracks: [PlaybackTrack] = []
    var attachedSubtitleURL: URL?
    var attachedSubtitleLanguage: String?
    var selectedAudioID: String?
    var selectedSubtitleIDs: [String] = []
    var loadedURL: URL?
    var lastSeek: TimeInterval = 0
    var calls: [String] = []
    var onStateChanged: (() -> Void)?
    var onTracksChanged: (() -> Void)?

    func emitTracksChange() {
        onTracksChanged?()
    }

    func emitStateChange() {
        onStateChanged?()
    }

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

    func stop() {
        isPlaying = false
        state = .idle
        calls.append("stop")
    }

    func seek(to seconds: TimeInterval) {
        lastSeek = seconds
        currentTime = seconds
        calls.append("seek")
    }

    func selectAudioTrack(id: String) -> Bool {
        selectedAudioID = id
        calls.append("select-audio")
        return true
    }

    func attachExternalSubtitle(from url: URL, languageCode: String?) -> Bool {
        guard capabilities.contains(.externalSubtitles) else { return false }
        attachedSubtitleURL = url
        attachedSubtitleLanguage = languageCode
        calls.append("attach-subtitle")
        return true
    }

    func selectSubtitleTrack(id: String?) -> Bool {
        selectedSubtitleIDs.append(id ?? "off")
        calls.append("select-subtitle")
        return true
    }
}
