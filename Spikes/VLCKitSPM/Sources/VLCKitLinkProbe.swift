import Foundation
import UIKit
import VLCKit

public struct VLCKitProbeTrack: Identifiable {
    public let id: Int
    public let name: String
}

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
    public func attachDrawable(_ view: UIView) {
        drawableView = view
        player.drawable = view
    }
    public func detachDrawable() {
        player.stop()
        player.drawable = nil
        drawableView = nil
    }
    public func load(_ media: VLCMedia, autoplay: Bool = false) {
        player.stop()
        player.media = media
        if autoplay { player.play() }
    }
    @discardableResult
    public func load(mediaURL: URL, subtitleURL: URL? = nil, autoplay: Bool = false) -> Bool {
        guard let media = VLCMedia(url: mediaURL) else { return false }
        if let subtitleURL {
            let slave = VLCMediaSlave(url: subtitleURL, type: .subtitle, priority: 0)
            guard media.addSlave(slave) else { return false }
        }
        load(media, autoplay: autoplay)
        return true
    }

    public var audioTracks: [VLCKitProbeTrack] {
        let names = player.audioTrackNames as? [String] ?? []
        let indexes = player.audioTrackIndexes as? [NSNumber] ?? []
        return zip(indexes, names).map { VLCKitProbeTrack(id: $0.0.intValue, name: $0.1) }
    }

    public var subtitleTracks: [VLCKitProbeTrack] {
        let names = player.videoSubTitlesNames as? [String] ?? []
        let indexes = player.videoSubTitlesIndexes as? [NSNumber] ?? []
        return zip(indexes, names).map { VLCKitProbeTrack(id: $0.0.intValue, name: $0.1) }
    }

    public func selectAudioTrack(id: Int) {
        player.currentAudioTrackIndex = Int32(id)
    }

    public func selectSubtitleTrack(id: Int) {
        player.currentVideoSubTitleIndex = Int32(id)
    }

    public func play() { player.play() }
    public func pause() { player.pause() }
    public func stop() {
        player.stop()
        player.media = nil
    }
}

extension VLCKitProbeSession {
    public func mediaPlayerStateChanged(_ notification: Notification!) {
        latestState = player.state
        onStateChanged?(latestState)
    }

    public func mediaPlayerBuffering(_ notification: Notification!, buffer: Float) {
        latestBuffering = buffer
        onBufferingChanged?(buffer)
    }
}
