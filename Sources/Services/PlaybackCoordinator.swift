import AVFoundation
import Foundation

enum PlaybackTrackKind: String, Equatable, Sendable {
    case audio
    case subtitle
}

struct PlaybackTrack: Identifiable, Equatable, Sendable {
    let id: String
    let kind: PlaybackTrackKind
    let displayName: String
    let languageCode: String?
    let isSelected: Bool
    let isExternal: Bool

    init(
        id: String,
        kind: PlaybackTrackKind,
        displayName: String,
        languageCode: String? = nil,
        isSelected: Bool = false,
        isExternal: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.languageCode = languageCode
        self.isSelected = isSelected
        self.isExternal = isExternal
    }
}

enum PlaybackEngineState: Equatable, Sendable {
    case idle
    case preparing
    case buffering
    case playing
    case paused
    case ended
    case failed(message: String)
}

/// Engine-neutral playback surface shared by iOS, iPadOS and tvOS.
@MainActor
protocol PlaybackEngine: AnyObject {
    var currentTime: TimeInterval { get }
    var isPlaying: Bool { get }
    var state: PlaybackEngineState { get }
    var audioTracks: [PlaybackTrack] { get }
    var subtitleTracks: [PlaybackTrack] { get }

    func load(_ url: URL)
    func play()
    func pause()
    func seek(to seconds: TimeInterval)
    @discardableResult func selectAudioTrack(id: String) -> Bool
    @discardableResult func selectSubtitleTrack(id: String?) -> Bool
}

extension PlaybackEngine {
    var state: PlaybackEngineState { isPlaying ? .playing : .paused }
    var audioTracks: [PlaybackTrack] { [] }
    var subtitleTracks: [PlaybackTrack] { [] }

    @discardableResult
    func selectAudioTrack(id: String) -> Bool { false }

    @discardableResult
    func selectSubtitleTrack(id: String?) -> Bool { false }
}

/// Native AVPlayer implementation for formats supported by Apple's media stack.
/// This adapter deliberately does not claim support for arbitrary containers/codecs.
@MainActor
final class AVPlayerPlaybackEngine: PlaybackEngine {
    let player: AVPlayer

    init(player: AVPlayer = AVPlayer()) {
        self.player = player
    }

    var currentTime: TimeInterval {
        let seconds = player.currentTime().seconds
        return seconds.isFinite ? max(0, seconds) : 0
    }

    var isPlaying: Bool {
        player.timeControlStatus == .playing
    }

    var state: PlaybackEngineState {
        guard let item = player.currentItem else { return .idle }
        switch item.status {
        case .unknown:
            return .preparing
        case .failed:
            return .failed(message: item.error?.localizedDescription ?? "Uppspelningen misslyckades.")
        case .readyToPlay:
            switch player.timeControlStatus {
            case .playing: return .playing
            case .waitingToPlayAtSpecifiedRate: return .buffering
            case .paused: return .paused
            @unknown default: return .paused
            }
        @unknown default:
            return .idle
        }
    }

    func load(_ url: URL) {
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func seek(to seconds: TimeInterval) {
        guard seconds.isFinite, seconds >= 0 else { return }
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }
}

/// Coordinates playback without exposing AVPlayer or a third-party engine to feature UI.
@MainActor
final class PlaybackCoordinator {
    private let engine: any PlaybackEngine

    init() {
        self.engine = AVPlayerPlaybackEngine()
    }

    init(engine: any PlaybackEngine) {
        self.engine = engine
    }

    var currentTime: TimeInterval { engine.currentTime }
    var isPlaying: Bool { engine.isPlaying }
    var state: PlaybackEngineState { engine.state }
    var audioTracks: [PlaybackTrack] { engine.audioTracks }
    var subtitleTracks: [PlaybackTrack] { engine.subtitleTracks }
    var avPlayer: AVPlayer? { (engine as? AVPlayerPlaybackEngine)?.player }

    func start(url: URL) {
        engine.load(url)
        engine.play()
    }

    func pause() {
        engine.pause()
    }

    func resume() {
        engine.play()
    }

    func seek(to seconds: TimeInterval) {
        engine.seek(to: seconds)
    }

    @discardableResult
    func selectAudioTrack(id: String) -> Bool {
        engine.selectAudioTrack(id: id)
    }

    @discardableResult
    func selectSubtitleTrack(id: String?) -> Bool {
        engine.selectSubtitleTrack(id: id)
    }
}
