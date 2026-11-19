import Foundation
import VLCKit

/// Compile-time probe only. This target is isolated from all production NEXUS targets.
public enum VLCKitLinkProbe {
    public static var mediaPlayerType: Any.Type {
        VLCMediaPlayer.self
    }

    public static func makeMediaPlayer() -> VLCMediaPlayer {
        VLCMediaPlayer()
    }
}
