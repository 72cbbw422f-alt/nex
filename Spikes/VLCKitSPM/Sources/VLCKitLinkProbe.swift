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
    private var pendingExternalSubtitleSelection = false
    private var hasSubtitleSelectionOverride = false
    public private(set) var selectedSubtitleTrackID: String?
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
                isSelected: hasSubtitleSelectionOverride
                    ? track.trackId == selectedSubtitleTrackID
                    : track.isSelected
            )
        }
    }

    public func selectAudioTrack(id: String) -> Bool {
        guard let track = player.audioTracks.first(where: { $0.trackId == id }) else {
            return false
        }
        track.isSelectedExclusively = true
        return true
    }

    public func disableAudioTrack() {
        player.deselectAllAudioTracks()
    }

    public func selectSubtitleTrack(id: String?) -> Bool {
        guard let id else {
            // An explicit user choice must override a pending automatic selection.
            pendingExternalSubtitleSelection = false
            player.deselectAllTextTracks()
            selectedSubtitleTrackID = nil
            hasSubtitleSelectionOverride = true
            return true
        }
        guard let track = player.textTracks.first(where: { $0.trackId == id }) else {
            return false
        }
        pendingExternalSubtitleSelection = false
        player.selectTextTracks([track])
        selectedSubtitleTrackID = track.trackId
        hasSubtitleSelectionOverride = true
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
        pendingExternalSubtitleSelection = false
        selectedSubtitleTrackID = nil
        hasSubtitleSelectionOverride = false
    }

    public func load(_ media: VLCMedia, autoplay: Bool = false) {
        player.stop()
        pendingExternalSubtitleSelection = false
        selectedSubtitleTrackID = nil
        hasSubtitleSelectionOverride = false
        player.media = media
        if autoplay { player.play() }
    }

    private func selectPendingExternalSubtitleIfAvailable() {
        guard pendingExternalSubtitleSelection else { return }
        guard let track = player.textTracks.first else { return }
        player.selectTextTracks([track])
        selectedSubtitleTrackID = track.trackId
        hasSubtitleSelectionOverride = true
        pendingExternalSubtitleSelection = false
    }

    @discardableResult
    public func load(mediaURL: URL, subtitleURL: URL? = nil, autoplay: Bool = false) -> Bool {
        guard let media = VLCMedia(url: mediaURL) else { return false }
        pendingExternalSubtitleSelection = subtitleURL != nil
        if let subtitleURL {
            let slave = VLCMediaSlave(url: subtitleURL, type: .subtitle, priority: 4)
            guard media.addSlave(slave) else {
                pendingExternalSubtitleSelection = false
                return false
            }
        }
        load(media, autoplay: autoplay)
        pendingExternalSubtitleSelection = subtitleURL != nil
        return true
    }

    public func play() { player.play() }
    public func pause() { player.pause() }

    public func stop() {
        player.stop()
        player.media = nil
        pendingExternalSubtitleSelection = false
        selectedSubtitleTrackID = nil
        hasSubtitleSelectionOverride = false
    }
}

extension VLCKitProbeSession {
    public func mediaPlayerStateChanged(_ notification: Notification!) {
        latestState = player.state
        selectPendingExternalSubtitleIfAvailable()
        onStateChanged?(latestState)
    }

    public func mediaPlayerBuffering(_ notification: Notification!, buffer: Float) {
        latestBuffering = buffer
        selectPendingExternalSubtitleIfAvailable()
        onBufferingChanged?(buffer)
    }
}
