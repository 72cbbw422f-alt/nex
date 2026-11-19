import AVKit
import SwiftUI

/// Rendering boundary for the native AVPlayer implementation.
/// Feature-level playback UI should not embed VideoPlayer directly; another
/// engine can provide its own surface without changing the surrounding shell.
struct AVPlayerPlaybackSurface: View {
    let player: AVPlayer

    var body: some View {
        VideoPlayer(player: player)
    }
}
