import Foundation
import VLCKit
import UIKit

/// Retains the weak VLCKit delegate for the full lifetime of the probe session.
@MainActor
public final class VLCKitProbeSession: NSObject, VLCMediaPlayerDelegate {
    public let player: VLCMediaPlayer
    private var drawableView: UIView?

    public private(set) var latestState: VLCMediaPlayerState = .stopped
    public private(set) var latestBuffering: Float = 0

    public var onStateChanged: ((VLCMediaPlayerState) -> Void)?
    public var onBufferingChanged: ((Float) -> Void)?

    public override init() {
        player = VLCMediaPlayer(options: [])
        super.init()
        player.delegate = self
    }

    /// The view must remain alive while the player renders into it.
    public func attachDrawable(_ view: UIView) {
        drawableView = view
        player.drawable = view
    }

    public func load(_ media: VLCMedia, autoplay: Bool = false) {
        player.stop()
        player.media = media
        if autoplay {
            player.play()
        }
    }

    /// Builds a media item and attaches an optional sidecar subtitle before playback.
    /// Returns false if media creation or subtitle attachment fails.
    @discardableResult
    public func load(
        mediaURL: URL,
        subtitleURL: URL? = nil,
        autoplay: Bool = false
    ) -> Bool {
        guard let media = VLCMedia(url: mediaURL) else { return false }

        if let subtitleURL {
            let subtitle = VLCMediaSlave(
                url: subtitleURL,
                type: .subtitle,
                priority: 0
            )
            guard media.addSlave(subtitle) else { return false }
        }

        load(media, autoplay: autoplay)
        return true
    }

    public func play() { player.play() }
    public func pause() { player.pause() }

    public func stop() {
        player.stop()
        player.drawable = nil
        drawableView = nil
    }

    public func mediaPlayerStateChanged(_ aNotification: Notification!) {
        let state = player.state
        latestState = state
        onStateChanged?(state)
    }

    public func mediaPlayerBuffering(_ aNotification: Notification!, buffer: Float) {
        latestBuffering = buffer
        onBufferingChanged?(buffer)
    }
}

/// Compile-time probe only. This target is isolated from all production NEXUS targets.
public enum VLCKitLinkProbe {
    public static var mediaPlayerType: Any.Type {
        VLCMediaPlayer.self
    }

    public static func makeMediaPlayer() -> VLCMediaPlayer {
        VLCMediaPlayer(options: [])
    }

    /// Compile-time proof of the documented external subtitle attachment API.
    /// The media slave must be attached before parsing or playback begins.
    public static func attachExternalSubtitle(
        to mediaURL: URL,
        subtitleURL: URL
    ) -> Bool {
        guard let media = VLCMedia(url: mediaURL) else {
            return false
        }

        let subtitle = VLCMediaSlave(
            url: subtitleURL,
            type: .subtitle,
            priority: 0
        )
        return media.addSlave(subtitle)
    }
}
