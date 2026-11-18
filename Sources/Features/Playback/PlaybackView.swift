import AVKit
import Combine
import SwiftUI

@MainActor
private final class PlaybackStatusModel: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?
    @Published private(set) var waitingMessage = "Ansluter till kanalen…"

    private let player: AVPlayer
    private var itemObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?

    init(player: AVPlayer) {
        self.player = player
        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            Task { @MainActor in
                guard let self, self.errorMessage == nil else { return }
                switch player.timeControlStatus {
                case .waitingToPlayAtSpecifiedRate:
                    self.isLoading = true
                    self.waitingMessage = "Buffrar strömmen…"
                case .playing:
                    self.isLoading = false
                case .paused:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    func start(url: URL) {
        errorMessage = nil
        isLoading = true
        waitingMessage = "Ansluter till kanalen…"
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        observeCurrentItem()
        player.play()
    }

    func retry(url: URL) {
        start(url: url)
    }

    func stop() {
        player.pause()
        itemObservation = nil
        timeControlObservation = nil
    }

    private func observeCurrentItem() {
        itemObservation = player.currentItem?.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self else { return }
                switch item.status {
                case .unknown:
                    self.isLoading = true
                    self.errorMessage = nil
                case .readyToPlay:
                    self.isLoading = false
                    self.errorMessage = nil
                case .failed:
                    self.isLoading = false
                    self.errorMessage = item.error?.localizedDescription ?? "Kanalen kunde inte startas. Kontrollera anslutningen eller prova igen."
                @unknown default:
                    self.isLoading = false
                    self.errorMessage = "Spelaren fick ett okänt svar från videokällan."
                }
            }
        }
    }
}

struct PlaybackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playbackState: PlaybackStatusModel
    private let url: URL
    private let player: AVPlayer
    private let title: String

    init(url: URL, title: String) {
        self.url = url
        self.title = title
        let player = AVPlayer()
        self.player = player
        _playbackState = StateObject(wrappedValue: PlaybackStatusModel(player: player))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VideoPlayer(player: player)
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
