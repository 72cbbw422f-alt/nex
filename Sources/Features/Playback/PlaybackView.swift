import Combine
import SwiftUI

@MainActor
private final class PlaybackStatusModel: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var waitingMessage = "Ansluter till kanalen…"
    @Published private(set) var audioTracks: [PlaybackTrack] = []
    @Published private(set) var subtitleTracks: [PlaybackTrack] = []
    @Published private(set) var hasLoadedTracks = false

    private let coordinator: PlaybackCoordinator

    init(coordinator: PlaybackCoordinator) {
        self.coordinator = coordinator
        coordinator.onStateChanged = { [weak self] in
            self?.refreshPlaybackState()
        }
        coordinator.onTracksChanged = { [weak self] in
            guard let self else { return }
            self.audioTracks = self.coordinator.audioTracks
            self.subtitleTracks = self.coordinator.subtitleTracks
            self.hasLoadedTracks = true
        }
    }

    func start(url: URL) {
        errorMessage = nil
        isLoading = true
        waitingMessage = "Ansluter till kanalen…"
        audioTracks = []
        subtitleTracks = []
        hasLoadedTracks = false
        coordinator.start(url: url)
        refreshPlaybackState()
    }

    func retry(url: URL) {
        start(url: url)
    }

    func selectAudioTrack(_ track: PlaybackTrack) {
        _ = coordinator.selectAudioTrack(id: track.id)
    }

    func selectSubtitleTrack(_ track: PlaybackTrack?) {
        _ = coordinator.selectSubtitleTrack(id: track?.id)
    }

    func stop() {
        coordinator.stop()
    }

    private func refreshPlaybackState() {
        switch coordinator.state {
        case .idle:
            isLoading = false
            errorMessage = nil
        case .preparing:
            isLoading = true
            waitingMessage = "Ansluter till kanalen…"
            errorMessage = nil
        case .buffering:
            isLoading = true
            waitingMessage = "Buffrar strömmen…"
            errorMessage = nil
        case .playing:
            isLoading = false
            errorMessage = nil
        case .paused:
            isLoading = false
        case .ended:
            isLoading = false
        case .failed(let message):
            isLoading = false
            errorMessage = message.isEmpty
                ? "Kanalen kunde inte startas. Kontrollera anslutningen eller prova igen."
                : message
        }
    }
}

@MainActor
private struct PlaybackSession {
    let coordinator: PlaybackCoordinator
    let surface: AnyView

    static func makeAVPlayerSession() -> PlaybackSession {
        let player = AVPlayer()
        let engine = AVPlayerPlaybackEngine(player: player)
        return PlaybackSession(
            coordinator: PlaybackCoordinator(engine: engine),
            surface: AnyView(AVPlayerPlaybackSurface(player: player))
        )
    }
}

struct PlaybackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playbackState: PlaybackStatusModel
    private let url: URL
    private let surface: AnyView
    private let title: String

    init(url: URL, title: String) {
        self.url = url
        self.title = title
        let session = PlaybackSession.makeAVPlayerSession()
        self.surface = session.surface
        _playbackState = StateObject(wrappedValue: PlaybackStatusModel(coordinator: session.coordinator))
    }

    @ViewBuilder
    private var trackControls: some View {
        if playbackState.hasLoadedTracks {
            HStack(spacing: 8) {
                if playbackState.audioTracks.isEmpty {
                    trackStatusLabel("Ljud · standard", icon: "waveform")
                } else {
                    Menu {
                        ForEach(playbackState.audioTracks) { track in
                            Button {
                                playbackState.selectAudioTrack(track)
                            } label: {
                                if track.isSelected {
                                    Label(track.displayName, systemImage: "checkmark")
                                } else {
                                    Text(track.displayName)
                                }
                            }
                        }
                    } label: {
                        trackMenuLabel("Ljud · \(playbackState.audioTracks.count)", icon: "waveform")
                    }
                    .accessibilityLabel("Välj ljudspår")
                }

                if playbackState.subtitleTracks.isEmpty {
                    trackStatusLabel("Undertexter · ej tillgängligt", icon: "captions.bubble")
                } else {
                    Menu {
                        Button {
                            playbackState.selectSubtitleTrack(nil)
                        } label: {
                            if !playbackState.subtitleTracks.contains(where: { $0.isSelected }) {
                                Label("Av", systemImage: "checkmark")
                            } else {
                                Text("Av")
                            }
                        }
                        ForEach(playbackState.subtitleTracks) { track in
                            Button {
                                playbackState.selectSubtitleTrack(track)
                            } label: {
                                if track.isSelected {
                                    Label(track.displayName, systemImage: "checkmark")
                                } else {
                                    Text(track.displayName)
                                }
                            }
                        }
                    } label: {
                        trackMenuLabel("Undertexter · \(playbackState.subtitleTracks.count)", icon: "captions.bubble")
                    }
                    .accessibilityLabel("Välj undertextspår")
                }
            }
        } else if playbackState.isLoading {
            trackStatusLabel("Läser spår…", icon: "waveform")
        }
    }

    private func trackMenuLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.black.opacity(0.62), in: Capsule())
    }

    private func trackStatusLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.78))
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(.black.opacity(0.48), in: Capsule())
            .accessibilityElement(children: .combine)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            surface
                .ignoresSafeArea(edges: .bottom)

            VStack {
                HStack(spacing: 12) {
                    Button {
                        playbackState.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(.black.opacity(0.58), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stäng spelaren")

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text("NEXUS · LIVE")
                            .font(.caption2.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(NexusTheme.accentLight)
                    }
                    Spacer()
                    trackControls
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)

                Spacer()

                if playbackState.isLoading {
                    HStack(spacing: 10) {
                        ProgressView().tint(.white)
                        Text(playbackState.waitingMessage)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.black.opacity(0.72), in: Capsule())
                    .accessibilityElement(children: .combine)
                }

                if let errorMessage = playbackState.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundStyle(NexusTheme.accentLight)
                        Text("Kanalen kunde inte spelas")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.78))
                            .multilineTextAlignment(.center)
                        Button {
                            playbackState.retry(url: url)
                        } label: {
                            Label("Försök igen", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 11)
                                .background(NexusTheme.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(22)
                    .frame(maxWidth: 340)
                    .background(.black.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
                }

                Spacer()

                HStack {
                    Text("Uppspelning via Apple AVPlayer")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
            .padding(.vertical, 8)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            playbackState.start(url: url)
        }
        .onDisappear {
            playbackState.stop()
        }
    }
}
