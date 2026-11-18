import AVFoundation
import Foundation

/// Engine-neutral playback surface shared by iOS, iPadOS and tvOS.
@MainActor
protocol PlaybackEngine: AnyObject {
    var currentTime: TimeInterval { get }
    var isPlaying: Bool { get }

    func load(_ url: URL)
    func play()
    func pause()
    func seek(to seconds: TimeInterval)
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
}
