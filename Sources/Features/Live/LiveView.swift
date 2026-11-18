import SwiftUI

private struct GuideChannel: Identifiable {
    let id: Int
    let name: String
    let now: String
    let next: String
    let progress: CGFloat
    let group: String
}

struct LiveView: View {
    @State private var selectedGroup = "Alla"
    @State private var favoriteIDs: Set<Int> = [1, 3]

    private let groups = ["Alla", "Favoriter", "Svenska", "Sport", "Film", "Dokumentär"]
    private let channels = [
        GuideChannel(id: 1, name: "SVT1", now: "Aktuellt", next: "Rapport", progress: 0.62, group: "Svenska"),
        GuideChannel(id: 2, name: "SVT2", now: "Vetenskapens värld", next: "Kulturstudion", progress: 0.34, group: "Dokumentär"),
        GuideChannel(id: 3, name: "TV4", now: "Nyhetsmorgon", next: "Efter fem", progress: 0.78, group: "Svenska"),
        GuideChannel(id: 4, name: "Kanal 5", now: "Gränsbevakarna", next: "Vägens hjältar", progress: 0.48, group: "Svenska"),
        GuideChannel(id: 5, name: "Discovery", now: "Gold Rush", next: "Expedition X", progress: 0.21, group: "Dokumentär")
    ]

    private var visibleChannels: [GuideChannel] {
        switch selectedGroup {
        case "Favoriter":
            return channels.filter { favoriteIDs.contains($0.id) }
        case "Alla":
            return channels
        default:
            return channels.filter { $0.group == selectedGroup }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                groupPicker
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

    private var groupPicker: some View {
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

            if visibleChannels.isEmpty {
                VStack(spacing: 9) {
                    Image(systemName: "star")
                        .font(.title2)
                        .foregroundStyle(NexusTheme.accentLight)
                    Text("Inga favoritkanaler ännu")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Tryck på stjärnan vid en kanal för att lägga till den här.")
                        .font(.caption)
                        .foregroundStyle(NexusTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
            } else {
                ForEach(visibleChannels) { channel in
                    channelRow(channel)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(NexusTheme.border, lineWidth: 1))
    }

    private func channelRow(_ channel: GuideChannel) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(channel.name)
                    .font(.headline.bold())
                    .foregroundStyle(NexusTheme.accentLight)
                Button {
                    toggleFavorite(channel.id)
                } label: {
                    Image(systemName: favoriteIDs.contains(channel.id) ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(favoriteIDs.contains(channel.id) ? NexusTheme.accentLight : NexusTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(favoriteIDs.contains(channel.id) ? "Ta bort favorit" : "Lägg till favorit")
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

    private func toggleFavorite(_ id: Int) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
        } else {
            favoriteIDs.insert(id)
        }
    }
}
