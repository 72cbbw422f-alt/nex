import Foundation
import UIKit
import VLCKit

public struct VLCKitProbeTrack: Identifiable, Equatable {
    public let id: String
    public let trackId: String
    public let name: String
    public let isSelected: Bool
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

    public var audioTracks: [VLCKitProbeTrack] {
        player.audioTracks.enumerated().map { index, track in
            VLCKitProbeTrack(
                id: "\(track.trackId)-\(index)",
                trackId: track.trackId,
                name: track.trackName,
                isSelected: track.isSelected
            )
        }
    }

    public var subtitleTracks: [VLCKitProbeTrack] {
        player.textTracks.enumerated().map { index, track in
            VLCKitProbeTrack(
                id: "\(track.trackId)-\(index)",
                trackId: track.trackId,
                name: track.trackName,
                isSelected: track.isSelected
            )
        }
    }

    public func selectAudioTrack(id: String) -> Bool {
        guard let track = player.audioTracks.first(where: { $0.trackId == id }) else {
            return false
        }
        track.selectedExclusively = true
        return true
    }

    public func disableAudioTrack() {
        player.deselectAllAudioTracks()
    }

    public func selectSubtitleTrack(id: String?) -> Bool {
        guard let id else {
            player.deselectAllTextTracks()
            return true
        }
        guard let track = player.textTracks.first(where: { $0.trackId == id }) else {
            return false
        }
        track.selectedExclusively = true
        return true
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
