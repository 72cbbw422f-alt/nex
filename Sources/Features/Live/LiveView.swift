import SwiftUI

private struct GuideChannel: Identifiable {
    let id: Int
    let name: String
    let now: String
    let next: String
    let progress: CGFloat
}

struct LiveView: View {
    @State private var selectedGroup = "Alla"
    private let groups = ["Alla", "Favoriter", "Svenska", "Sport", "Film", "Dokumentär"]
    private let channels = [
        GuideChannel(id: 1, name: "SVT1", now: "Aktuellt", next: "Rapport", progress: 0.62),
        GuideChannel(id: 2, name: "SVT2", now: "Vetenskapens värld", next: "Kulturstudion", progress: 0.34),
        GuideChannel(id: 3, name: "TV4", now: "Nyhetsmorgon", next: "Efter fem", progress: 0.78),
        GuideChannel(id: 4, name: "Kanal 5", now: "Gränsbevakarna", next: "Vägens hjältar", progress: 0.48),
        GuideChannel(id: 5, name: "Discovery", now: "Gold Rush", next: "Expedition X", progress: 0.21)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(groups, id: \.self) { group in
                            Button {
                                selectedGroup = group
                            } label: {
                                Text(group)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 9)
                                    .background(selectedGroup == group ? NexusTheme.accent : NexusTheme.surface, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                guide
            }
            .padding(20)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .navigationTitle("Live TV")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("LIVE TV", systemImage: "dot.radiowaves.left.and.right")
                .font(.caption.weight(.bold))
                .tracking(1.5)
                .foregroundStyle(NexusTheme.accentLight)
            Text("På TV just nu")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Kanaler, favoriter och programguide samlade på ett ställe.")
                .font(.subheadline)
                .foregroundStyle(NexusTheme.secondaryText)
        }
    }

    private var guide: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("KANAL").frame(width: 112, alignment: .leading)
                Text("NU").frame(maxWidth: .infinity, alignment: .leading)
                Text("NÄSTA").frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.caption2.weight(.bold))
            .foregroundStyle(NexusTheme.secondaryText)
            .padding(12)

            ForEach(channels) { channel in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(channel.name)
                            .font(.headline.bold())
                            .foregroundStyle(NexusTheme.accentLight)
                        Image(systemName: "heart")
                            .font(.caption)
                            .foregroundStyle(NexusTheme.secondaryText)
                    }
                    .frame(width: 102, alignment: .leading)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(channel.now)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.12))
                                Capsule().fill(NexusTheme.accent).frame(width: proxy.size.width * channel.progress)
                            }
                        }
                        .frame(height: 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(channel.next)
                        .font(.caption)
                        .foregroundStyle(NexusTheme.secondaryText)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(13)
                .background(NexusTheme.surface)
                .overlay(alignment: .bottom) { Rectangle().fill(NexusTheme.border).frame(height: 1) }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(NexusTheme.border, lineWidth: 1))
    }
}
