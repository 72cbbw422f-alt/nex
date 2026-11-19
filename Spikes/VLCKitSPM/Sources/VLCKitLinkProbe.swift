import Foundation
import VLCKit

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
