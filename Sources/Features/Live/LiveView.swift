import SwiftUI

private struct GuideChannel: Identifiable {
    let id: Int
    let name: String
    let logo: URL?
    let groupID: String?
}

private struct GuideGroup: Identifiable {
    let id: String
    let title: String
}

struct LiveView: View {
    @State private var selectedGroup = "Alla"
    @State private var favoriteIDs: Set<Int> = [1, 3]
    @State private var liveCategories: [XtreamLiveCategory] = []
    @State private var liveStreams: [XtreamLiveStream] = []
    @State private var activeProfile: SavedProviderConnection?
    @State private var isLoading = false
    @State private var loadMessage: String?
    @State private var expandedEPGChannel: Int?
    @State private var epgByChannel: [Int: [XtreamEPGProgram]] = [:]
    @State private var epgLoadingChannel: Int?

    private let sampleChannels: [GuideChannel] = [
        GuideChannel(id: 1, name: "SVT1", logo: nil, groupID: "Svenska"),
        GuideChannel(id: 2, name: "SVT2", logo: nil, groupID: "Dokumentär"),
        GuideChannel(id: 3, name: "TV4", logo: nil, groupID: "Svenska"),
        GuideChannel(id: 4, name: "Kanal 5", logo: nil, groupID: "Svenska"),
        GuideChannel(id: 5, name: "Discovery", logo: nil, groupID: "Dokumentär")
    ]

    private var usingProviderData: Bool { activeProfile != nil && !liveStreams.isEmpty }
    private var channels: [GuideChannel] {
        if usingProviderData {
            return liveStreams.map { GuideChannel(id: $0.streamID, name: $0.name, logo: $0.streamIcon, groupID: $0.categoryID) }
        }
        return sampleChannels
    }

    private var groups: [GuideGroup] {
        if !liveCategories.isEmpty {
            return [GuideGroup(id: "Alla", title: "Alla"), GuideGroup(id: "Favoriter", title: "Favoriter")] +
                liveCategories.map { GuideGroup(id: $0.categoryID, title: $0.categoryName) }
        }
        return ["Alla", "Favoriter", "Svenska", "Sport", "Film", "Dokumentär"].map { GuideGroup(id: $0, title: $0) }
    }

    private var visibleChannels: [GuideChannel] {
        switch selectedGroup {
        case "Favoriter":
            return channels.filter { favoriteIDs.contains($0.id) }
        case "Alla":
            return channels
        default:
            if usingProviderData {
                return channels.filter { $0.groupID == selectedGroup }
            }
            return channels.filter { $0.groupID == selectedGroup }
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
        .task { await loadProviderChannels() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("LIVE TV", systemImage: "dot.radiowaves.left.and.right")
                .font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(NexusTheme.accentLight)
            Text("På TV just nu").font(.largeTitle.bold()).foregroundStyle(.white)
            Text("Kanaler, favoriter och programguide samlade på ett ställe.")
                .font(.subheadline).foregroundStyle(NexusTheme.secondaryText)

            HStack(spacing: 10) {
                if isLoading { ProgressView().tint(NexusTheme.accentLight) }
                Text(loadMessage ?? (usingProviderData ? "Hämtar kanaler från \(activeProfile?.displayName ?? "server")" : "Visar förhandsvisning – anslut en Xtream-källa för riktiga kanaler."))
                    .font(.caption).foregroundStyle(NexusTheme.secondaryText)
                Spacer()
                Button {
                    Task { await loadProviderChannels() }
                } label: {
                    Image(systemName: "arrow.clockwise").foregroundStyle(NexusTheme.accentLight)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .accessibilityLabel("Uppdatera kanaler")
            }
            .padding(12)
            .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var groupPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(groups, id: \.id) { group in
                    Button { selectedGroup = group.id } label: {
                        Text(group.title)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 15).padding(.vertical, 9)
                            .background(selectedGroup == group.id ? NexusTheme.accent : NexusTheme.surface, in: Capsule())
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
                Text("PROGRAMINFO").frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.caption2.weight(.bold)).foregroundStyle(NexusTheme.secondaryText).padding(12)

            if visibleChannels.isEmpty {
                VStack(spacing: 9) {
                    Image(systemName: selectedGroup == "Favoriter" ? "star" : "tv")
                        .font(.title2).foregroundStyle(NexusTheme.accentLight)
                    Text(selectedGroup == "Favoriter" ? "Inga favoritkanaler ännu" : "Inga kanaler i den här gruppen")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text("Använd stjärnan vid en kanal för att lägga till eller ta bort favoriter.")
                        .font(.caption).foregroundStyle(NexusTheme.secondaryText).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(28)
            } else {
                ForEach(visibleChannels) { channel in channelRow(channel) }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(NexusTheme.border, lineWidth: 1))
    }

    private func channelRow(_ channel: GuideChannel) -> some View {
        VStack(spacing: 0) {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Button { Task { await toggleEPG(channel) } } label: {
                    Text(channel.name).font(.headline.bold()).foregroundStyle(NexusTheme.accentLight).lineLimit(2)
                }
                .buttonStyle(.plain)
                Button { toggleFavorite(channel.id) } label: {
                    Image(systemName: favoriteIDs.contains(channel.id) ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(favoriteIDs.contains(channel.id) ? NexusTheme.accentLight : NexusTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(favoriteIDs.contains(channel.id) ? "Ta bort favorit" : "Lägg till favorit")
            }
            .frame(width: 102, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                Text(usingProviderData ? "Visa programguide" : "Exempelkanal")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                Text(usingProviderData ? "Tryck på kanalnamnet för EPG" : "Ingen riktig programdata")
                    .font(.caption).foregroundStyle(NexusTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(13)
        .background(NexusTheme.surface)
        .overlay(alignment: .bottom) { Rectangle().fill(NexusTheme.border).frame(height: 1) }

        if expandedEPGChannel == channel.id {
            epgPanel(for: channel)
        }
        }
    }

    @ViewBuilder
    private func epgPanel(for channel: GuideChannel) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("PROGRAMGUIDE").font(.caption.weight(.bold)).foregroundStyle(NexusTheme.secondaryText)
                Spacer()
                if epgLoadingChannel == channel.id { ProgressView().tint(NexusTheme.accentLight) }
            }
            if let programs = epgByChannel[channel.id], !programs.isEmpty {
                ForEach(programs.prefix(5)) { program in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(program.startTimestamp.map { $0.formatted(date: .omitted, time: .shortened) } ?? "--:--")
                                .font(.caption.monospacedDigit()).foregroundStyle(NexusTheme.accentLight)
                            Text(program.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                        }
                        if !program.description.isEmpty {
                            Text(program.description).font(.caption).foregroundStyle(NexusTheme.secondaryText).lineLimit(2)
                        }
                    }
                }
            } else if epgByChannel[channel.id] != nil {
                Text("Ingen programinformation tillgänglig.").font(.caption).foregroundStyle(NexusTheme.secondaryText)
            } else if epgLoadingChannel != channel.id {
                Text("Tryck på kanalnamnet för att hämta program.").font(.caption).foregroundStyle(NexusTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(NexusTheme.elevatedSurface)
    }

    @MainActor
    private func toggleEPG(_ channel: GuideChannel) async {
        if expandedEPGChannel == channel.id {
            expandedEPGChannel = nil
            return
        }
        expandedEPGChannel = channel.id
        guard usingProviderData, let profile = activeProfile else { return }
        if epgByChannel[channel.id] != nil { return }
        guard let password = try? KeychainCredentialStore.shared.password(
            provider: profile.provider, baseURL: profile.baseURL, username: profile.username
        ), !password.isEmpty else { return }
        epgLoadingChannel = channel.id
        defer { epgLoadingChannel = nil }
        let configuration = ProviderConnectionConfiguration(provider: profile.provider, baseURL: profile.baseURL, username: profile.username)
        do {
            epgByChannel[channel.id] = try await XtreamConnector().shortEPG(
                configuration: configuration, credentials: ProviderCredentials(password: password), streamID: channel.id
            )
        } catch {
            epgByChannel[channel.id] = []
            loadMessage = "EPG kunde inte hämtas för \(channel.name): \(error.localizedDescription)"
        }
    }

    @MainActor
    private func loadProviderChannels() async {
        guard let profile = ProviderConnectionStore.shared.load().first(where: { $0.provider == .xtream }) else {
            activeProfile = nil
            liveCategories = []
            liveStreams = []
            loadMessage = "Ingen sparad Xtream-anslutning. Visar exempelkanaler."
            return
        }

        activeProfile = profile
        guard let password = try? KeychainCredentialStore.shared.password(
            provider: profile.provider, baseURL: profile.baseURL, username: profile.username
        ) , !password.isEmpty else {
            liveCategories = []
            liveStreams = []
            loadMessage = "Lösenord saknas i nyckelringen. Öppna Anslutningar och spara profilen igen."
            return
        }

        isLoading = true
        defer { isLoading = false }
        let configuration = ProviderConnectionConfiguration(provider: profile.provider, baseURL: profile.baseURL, username: profile.username)
        let credentials = ProviderCredentials(password: password)
        do {
            let connector = XtreamConnector()
            async let categories = connector.liveCategories(configuration: configuration, credentials: credentials)
            async let streams = connector.liveStreams(configuration: configuration, credentials: credentials)
            liveCategories = try await categories
            liveStreams = try await streams
            selectedGroup = "Alla"
            loadMessage = "Hämtade \(liveStreams.count) kanaler i \(liveCategories.count) kategorier från \(profile.displayName)."
        } catch {
            liveCategories = []
            liveStreams = []
            loadMessage = "Kunde inte hämta kanaler: \(error.localizedDescription)"
        }
    }

    private func toggleFavorite(_ id: Int) {
        if favoriteIDs.contains(id) { favoriteIDs.remove(id) }
        else { favoriteIDs.insert(id) }
    }
}
