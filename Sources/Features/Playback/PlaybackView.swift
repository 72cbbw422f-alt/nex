import AVKit
import SwiftUI

struct PlaybackView: View {
    @Environment(\.dismiss) private var dismiss
    private let url: URL
    private let player: AVPlayer
    private let coordinator: PlaybackCoordinator

    init(url: URL, title: String) {
        self.url = url
        self.title = title
        let player = AVPlayer()
        self.player = player
        self.coordinator = PlaybackCoordinator(engine: AVPlayerPlaybackEngine(player: player))
    }

    private let title: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VideoPlayer(player: player)
                .ignoresSafeArea(edges: .bottom)

            VStack {
                HStack(spacing: 12) {
                    Button {
                        coordinator.pause()
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

                HStack {
                    Text("Uppspelning via Apple AVPlayer")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            coordinator.start(url: url)
        }
        .onDisappear {
            coordinator.pause()
        }
    }
}
