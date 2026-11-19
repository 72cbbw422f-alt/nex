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
    var duration: TimeInterval? { get }
    var isSeekable: Bool { get }
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
    /// Unknown or indefinite duration is represented as nil (common for live streams).
    var duration: TimeInterval? { nil }
    var isSeekable: Bool { false }
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
    private var audioGroup: AVMediaSelectionGroup?
    private var subtitleGroup: AVMediaSelectionGroup?
    private var audioOptions: [String: AVMediaSelectionOption] = [:]
    private var subtitleOptions: [String: AVMediaSelectionOption] = [:]
    private var audioTrackCache: [PlaybackTrack] = []
    private var subtitleTrackCache: [PlaybackTrack] = []
    private var selectionLoadTask: Task<Void, Never>?
    var onTracksChanged: (() -> Void)?

    init(player: AVPlayer = AVPlayer()) {
        self.player = player
    }

    var currentTime: TimeInterval {
        let seconds = player.currentTime().seconds
        return seconds.isFinite ? max(0, seconds) : 0
    }

    var duration: TimeInterval? {
        guard let item = player.currentItem else { return nil }
        let seconds = item.duration.seconds
        return seconds.isFinite && seconds > 0 ? seconds : nil
    }

    var isSeekable: Bool {
        guard let item = player.currentItem else { return false }
        return !item.seekableTimeRanges.isEmpty
    }

    var isPlaying: Bool {
        player.timeControlStatus == .playing
    }

    var audioTracks: [PlaybackTrack] { audioTrackCache }
    var subtitleTracks: [PlaybackTrack] { subtitleTrackCache }

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
        selectionLoadTask?.cancel()
        audioGroup = nil
        subtitleGroup = nil
        audioOptions = [:]
        subtitleOptions = [:]
        audioTrackCache = []
        subtitleTrackCache = []
        onTracksChanged?()

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        selectionLoadTask = Task { [weak self, weak item] in
            guard let self, let item else { return }
            async let audio = Self.loadSelectionGroup(.audible, from: item.asset)
            async let subtitles = Self.loadSelectionGroup(.legible, from: item.asset)
            let (loadedAudio, loadedSubtitles) = await (audio, subtitles)
            guard !Task.isCancelled, self.player.currentItem === item else { return }
            self.audioGroup = loadedAudio
            self.subtitleGroup = loadedSubtitles
            self.audioOptions = Self.optionMap(for: loadedAudio, prefix: "audio")
            self.subtitleOptions = Self.optionMap(for: loadedSubtitles, prefix: "subtitle")
            self.audioTrackCache = Self.tracks(from: loadedAudio, prefix: "audio", kind: .audio, selected: item.currentMediaSelection)
            self.subtitleTrackCache = Self.tracks(from: loadedSubtitles, prefix: "subtitle", kind: .subtitle, selected: item.currentMediaSelection)
            self.onTracksChanged?()
        }
    }

    @discardableResult
    func selectAudioTrack(id: String) -> Bool {
        guard let option = audioOptions[id], let group = audioGroup, let item = player.currentItem else { return false }
        item.select(option, in: group)
        audioTrackCache = Self.tracks(from: group, prefix: "audio", kind: .audio, selected: item.currentMediaSelection)
        onTracksChanged?()
        return true
    }

    @discardableResult
    func selectSubtitleTrack(id: String?) -> Bool {
        guard let group = subtitleGroup, let item = player.currentItem else { return false }
        if let id {
            guard let option = subtitleOptions[id] else { return false }
            item.select(option, in: group)
        } else {
            item.select(nil, in: group)
        }
        subtitleTrackCache = Self.tracks(from: group, prefix: "subtitle", kind: .subtitle, selected: item.currentMediaSelection)
        onTracksChanged?()
        return true
    }

    private static func loadSelectionGroup(_ characteristic: AVMediaCharacteristic, from asset: AVAsset) async -> AVMediaSelectionGroup? {
        try? await asset.loadMediaSelectionGroup(for: characteristic)
    }

    private static func optionMap(for group: AVMediaSelectionGroup?, prefix: String) -> [String: AVMediaSelectionOption] {
        guard let group else { return [:] }
        return Dictionary(uniqueKeysWithValues: group.options.enumerated().map { index, option in
            ("\(prefix)-\(index)", option)
        })
    }

    private static func tracks(
        from group: AVMediaSelectionGroup?,
        prefix: String,
        kind: PlaybackTrackKind,
        selected selection: AVMediaSelection
    ) -> [PlaybackTrack] {
        guard let group else { return [] }
        let selectedOption = selection.selectedMediaOption(in: group)
        return group.options.enumerated().map { index, option in
            PlaybackTrack(
                id: "\(prefix)-\(index)",
                kind: kind,
                displayName: option.displayName,
                languageCode: option.locale?.identifier,
                isSelected: option == selectedOption
            )
        }
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
    var duration: TimeInterval? { engine.duration }
    var isSeekable: Bool { engine.isSeekable }
    var isPlaying: Bool { engine.isPlaying }
    var state: PlaybackEngineState { engine.state }
    var audioTracks: [PlaybackTrack] { engine.audioTracks }
    var subtitleTracks: [PlaybackTrack] { engine.subtitleTracks }
    var avPlayer: AVPlayer? { (engine as? AVPlayerPlaybackEngine)?.player }
    var onTracksChanged: (() -> Void)? {
        get { (engine as? AVPlayerPlaybackEngine)?.onTracksChanged }
        set { (engine as? AVPlayerPlaybackEngine)?.onTracksChanged = newValue }
    }

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
