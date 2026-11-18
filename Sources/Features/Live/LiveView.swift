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

private struct LiveEPGCacheKey: Hashable {
    let provider: String
    let server: String
    let username: String
    let channelID: Int
}

private struct TimelineProgramPlacement: Identifiable {
    let program: XtreamEPGProgram
    let start: Date
    let end: Date
    let lane: Int

    var id: String { program.id }
}

struct LiveView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isCompactWidth: Bool { horizontalSizeClass == .compact }
    private var channelColumnWidth: CGFloat { isCompactWidth ? 94 : 112 }
    private var minimumProgrammeCardWidth: CGFloat { isCompactWidth ? 68 : 76 }
    @State private var selectedGroup = "Alla"
    @State private var favoriteIDs: Set<Int> = [1, 3]
    @State private var liveCategories: [XtreamLiveCategory] = []
    @State private var liveStreams: [XtreamLiveStream] = []
    @State private var activeProfile: SavedProviderConnection?
    @State private var isLoading = false
    @State private var providerLoadRequestID: UUID?
    @State private var loadMessage: String?
    @State private var expandedEPGChannel: Int?
    @State private var epgByChannel: [LiveEPGCacheKey: [XtreamEPGProgram]] = [:]
    @State private var epgFetchedAt: [LiveEPGCacheKey: Date] = [:]
    @State private var epgErrors: [LiveEPGCacheKey: String] = [:]
    @State private var epgLoadingChannel: Int?
    @State private var epgRequestID: UUID?
    @State private var isLoadingTimeline = false
    @State private var timelineMessage: String?
    @State private var timelineOffsetHours = 0

    private let sampleChannels: [GuideChannel] = [
        GuideChannel(id: 1, name: "SVT1", logo: nil, groupID: "Svenska"),
        GuideChannel(id: 2, name: "SVT2", logo: nil, groupID: "Dokumentär"),
        GuideChannel(id: 3, name: "TV4", logo: nil, groupID: "Svenska"),
        GuideChannel(id: 4, name: "Kanal 5", logo: nil, groupID: "Svenska"),
        GuideChannel(id: 5, name: "Discovery", logo: nil, groupID: "Dokumentär")
    ]

    private var favoriteStorageKey: String? {
        guard let profile = activeProfile else { return nil }
        let server = profile.baseURL.absoluteString.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "nexus.live-favorites.\(profile.provider.rawValue).\(server).\(profile.username)"
    }

    private func epgCacheKey(for channelID: Int) -> LiveEPGCacheKey {
        let server = activeProfile?.baseURL.absoluteString.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? "preview"
        return LiveEPGCacheKey(
            provider: activeProfile?.provider.rawValue ?? "preview",
            server: server,
            username: activeProfile?.username ?? "",
            channelID: channelID
        )
    }

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
            VStack(alignment: .leading, spacing: isCompactWidth ? 16 : 22) {
                header
                groupPicker
                timelineSection
                guide
            }
            .padding(isCompactWidth ? 14 : 20)
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

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("PROGRAMGUIDE").font(.caption.weight(.bold)).tracking(1.2).foregroundStyle(NexusTheme.accentLight)
                    Text("Tidslinje · \(timelineStart.formatted(date: .abbreviated, time: .omitted))") .font(isCompactWidth ? .headline : .title3).bold().foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
                }
                Spacer()
                HStack(spacing: 7) {
                    Button { shiftTimeline(by: -6) } label: {
                        Image(systemName: "chevron.left").frame(width: 30, height: 30)
                    }
                    .accessibilityLabel("Sex timmar bakåt")
                    Button { shiftTimeline(by: 0) } label: {
                        Text("Nu").font(.caption.weight(.semibold)).padding(.horizontal, 8).frame(height: 30)
                    }
                    .disabled(timelineOffsetHours == 0)
                    Button { shiftTimeline(by: 6) } label: {
                        Image(systemName: "chevron.right").frame(width: 30, height: 30)
                    }
                    .accessibilityLabel("Sex timmar framåt")
                    Button { Task { await loadTimeline() } } label: {
                        HStack(spacing: 5) {
                            if isLoadingTimeline { ProgressView().tint(.white) }
                            Text(isLoadingTimeline ? "Hämtar…" : "Ladda")
                        }.font(.caption.weight(.semibold)).padding(.horizontal, 10).frame(height: 30)
                         .background(NexusTheme.accent, in: Capsule()).foregroundStyle(.white)
                    }.disabled(isLoadingTimeline || !usingProviderData)
                }
                .foregroundStyle(.white)
                .buttonStyle(.plain)
                .background(NexusTheme.elevatedSurface, in: Capsule())
            }
            Text(timelineMessage ?? "Hämtar program för upp till 8 synliga kanaler.").font(.caption).foregroundStyle(NexusTheme.secondaryText)
            if !timelineChannels.isEmpty {
                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 0) {
                            Text("KANAL").font(.caption2.bold()).foregroundStyle(NexusTheme.secondaryText).frame(width: channelColumnWidth, alignment: .leading)
                            HStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { hour in
                                    Text(timelineStart.addingTimeInterval(Double(hour) * 3600).formatted(date: .omitted, time: .shortened))
                                        .font(.system(size: 9, weight: .medium, design: .rounded).monospacedDigit())
                                        .foregroundStyle(NexusTheme.secondaryText)
                                        .frame(width: timelineHourWidth, alignment: .leading)
                                }
                            }.frame(width: timelineWidth, alignment: .leading)
                        }
                        ForEach(timelineChannels) { channel in
                            HStack(spacing: 0) {
                                HStack(spacing: 6) { channelLogo(channel, size: 22); Text(channel.name).font(.caption.weight(.semibold)).foregroundStyle(.white).lineLimit(2) }.frame(width: channelColumnWidth, alignment: .leading)
                                timelineRow(for: channel)
                            }
                        }
                    }
                }
            }
        }.padding(14).background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(NexusTheme.border, lineWidth: 1))
    }

    private var timelineChannels: [GuideChannel] {
        Array(visibleChannels.filter { epgByChannel[epgCacheKey(for: $0.id)] != nil && !(epgByChannel[epgCacheKey(for: $0.id)]?.isEmpty ?? true) }.prefix(8))
    }

    private var timelineStart: Date {
        let currentHour = Calendar.current.dateInterval(of: .hour, for: Date())?.start ?? Date()
        return currentHour.addingTimeInterval(Double(timelineOffsetHours) * 3600)
    }

    private func shiftTimeline(by hours: Int) {
        guard !isLoadingTimeline else { return }
        timelineOffsetHours = hours == 0 ? 0 : timelineOffsetHours + hours
        Task { await loadTimeline() }
    }

    private var timelineHourWidth: CGFloat { isCompactWidth ? 96 : 120 }
    private var timelineWidth: CGFloat { timelineHourWidth * 6 }

    private func timelinePlacements(for channel: GuideChannel) -> [TimelineProgramPlacement] {
        let windowEnd = timelineStart.addingTimeInterval(6 * 3600)
        let programs = (epgByChannel[epgCacheKey(for: channel.id)] ?? []).compactMap { program -> (XtreamEPGProgram, Date, Date)? in
            guard let start = program.startTimestamp,
                  let end = program.endTimestamp,
                  end > start,
                  end > timelineStart,
                  start < windowEnd else { return nil }
            return (program, max(start, timelineStart), min(end, windowEnd))
        }.sorted { $0.1 == $1.1 ? $0.2 < $1.2 : $0.1 < $1.1 }

        var laneEndTimes: [Date] = []
        var placements: [TimelineProgramPlacement] = []
        // Reserve enough horizontal space for a readable compact card. This is a
        // visual collision interval only; the displayed programme duration stays true.
        let minimumCardWidth = minimumProgrammeCardWidth
        let minimumCardDuration = TimeInterval(minimumCardWidth / timelineHourWidth * 3600)
        for (program, clippedStart, clippedEnd) in programs {
            let visualEnd = min(windowEnd, max(clippedEnd, clippedStart.addingTimeInterval(minimumCardDuration)))
            let lane = laneEndTimes.firstIndex(where: { $0 <= clippedStart }) ?? laneEndTimes.count
            if lane == laneEndTimes.count {
                laneEndTimes.append(visualEnd)
            } else {
                laneEndTimes[lane] = visualEnd
            }
            placements.append(TimelineProgramPlacement(program: program, start: clippedStart, end: clippedEnd, lane: lane))
        }
        return placements
    }

    private func timelineRow(for channel: GuideChannel) -> some View {
        let placements = timelinePlacements(for: channel)
        let laneCount = max(1, (placements.map(\.lane).max() ?? 0) + 1)
        let laneHeight: CGFloat = 48
        let rowHeight = CGFloat(laneCount) * laneHeight
        return ZStack(alignment: .topLeading) {
            VStack(spacing: 1) {
                ForEach(0..<laneCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(NexusTheme.elevatedSurface.opacity(0.42))
                        .frame(height: laneHeight - 1)
                }
            }
            .frame(width: timelineWidth, height: rowHeight)
            ForEach(placements) { placement in
                VStack(alignment: .leading, spacing: 3) {
                    Text(placement.start.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 9, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundStyle(NexusTheme.accentLight)
                    Text(placement.program.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .padding(5)
                .frame(
                    width: max(minimumProgrammeCardWidth - 3, CGFloat(placement.end.timeIntervalSince(placement.start) / 3600) * timelineHourWidth - 3),
                    height: laneHeight - 2,
                    alignment: .leading
                )
                .background(NexusTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(NexusTheme.border, lineWidth: 0.7))
                .offset(
                    x: CGFloat(placement.start.timeIntervalSince(timelineStart) / 3600) * timelineHourWidth,
                    y: CGFloat(placement.lane) * laneHeight
                )
            }
        }
        .frame(width: timelineWidth, height: rowHeight, alignment: .topLeading)
        .clipped()
        .overlay(alignment: .leading) {
            let elapsed = Date().timeIntervalSince(timelineStart)
            if elapsed >= 0 && elapsed <= 6 * 3600 {
                Rectangle().fill(Color.red.opacity(0.9)).frame(width: 1.5)
                    .offset(x: CGFloat(elapsed / 3600) * timelineHourWidth)
            }
        }
    }

    @MainActor
    private func loadTimeline() async {
        guard usingProviderData, let profile = activeProfile else { timelineMessage = "Anslut en Xtream-källa för att läsa den riktiga programguiden."; return }
        guard let password = try? KeychainCredentialStore.shared.password(provider: profile.provider, baseURL: profile.baseURL, username: profile.username), !password.isEmpty else { timelineMessage = "Lösenord saknas i nyckelringen. Spara anslutningen igen."; return }
        isLoadingTimeline = true
        timelineMessage = nil
        defer { isLoadingTimeline = false }
        let configuration = ProviderConnectionConfiguration(provider: profile.provider, baseURL: profile.baseURL, username: profile.username)
        let credentials = ProviderCredentials(password: password)
        let channelsToLoad = Array(visibleChannels.prefix(8))
        let groupAtStart = selectedGroup
        for channel in channelsToLoad {
            let cacheKey = epgCacheKey(for: channel.id)
            let cacheIsFresh = epgFetchedAt[cacheKey].map { Date().timeIntervalSince($0) < (epgErrors[cacheKey] == nil ? 300 : 60) } ?? false
            if cacheIsFresh { continue }
            do {
                let programs = try await XtreamConnector().shortEPG(configuration: configuration, credentials: credentials, streamID: channel.id, limit: 8)
                guard activeProfile?.baseURL == profile.baseURL, activeProfile?.username == profile.username else { return }
                epgByChannel[cacheKey] = programs
                epgErrors[cacheKey] = nil
                epgFetchedAt[cacheKey] = Date()
            } catch {
                guard activeProfile?.baseURL == profile.baseURL, activeProfile?.username == profile.username else { return }
                epgByChannel[cacheKey] = []
                epgErrors[cacheKey] = error.localizedDescription
                epgFetchedAt[cacheKey] = Date()
            }
            guard selectedGroup == groupAtStart else { return }
        }
        guard activeProfile?.baseURL == profile.baseURL, activeProfile?.username == profile.username, selectedGroup == groupAtStart else { return }
        let available = channelsToLoad.filter { !(epgByChannel[epgCacheKey(for: $0.id)]?.isEmpty ?? true) }.count
        timelineMessage = "Visar programdata för \(available) av \(channelsToLoad.count) kanaler. Högst 8 kanaler hämtas per omgång."
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

    @ViewBuilder
    private func channelLogo(_ channel: GuideChannel, size: CGFloat) -> some View {
        if let logo = channel.logo {
            AsyncImage(url: logo) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .empty, .failure:
                    Image(systemName: "tv").resizable().scaledToFit().padding(size * 0.22)
                        .foregroundStyle(NexusTheme.secondaryText)
                @unknown default:
                    Image(systemName: "tv").resizable().scaledToFit().padding(size * 0.22)
                        .foregroundStyle(NexusTheme.secondaryText)
                }
            }
            .frame(width: size, height: size)
            .background(NexusTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Image(systemName: "tv")
                .font(.system(size: size * 0.55, weight: .medium))
                .foregroundStyle(NexusTheme.secondaryText)
                .frame(width: size, height: size)
                .background(NexusTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func channelRow(_ channel: GuideChannel) -> some View {
        VStack(spacing: 0) {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    channelLogo(channel, size: 30)
                    Button { Task { await toggleEPG(channel) } } label: {
                        Text(channel.name).font(.headline.bold()).foregroundStyle(NexusTheme.accentLight).lineLimit(2)
                    }
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
            .frame(width: channelColumnWidth, alignment: .leading)

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
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 7) {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundStyle(NexusTheme.accentLight)
                Text("PROGRAM FÖR \(channel.name.uppercased())")
                    .font(.caption.weight(.bold))
                    .tracking(0.6)
                    .foregroundStyle(NexusTheme.secondaryText)
                Spacer()
                if epgLoadingChannel == channel.id {
                    ProgressView().tint(NexusTheme.accentLight)
                } else if epgFetchedAt[epgCacheKey(for: channel.id)] != nil {
                    Text("Uppdaterad")
                        .font(.caption2)
                        .foregroundStyle(NexusTheme.secondaryText)
                }
            }

            if let programs = epgByChannel[epgCacheKey(for: channel.id)], !programs.isEmpty {
                ForEach(programs.prefix(5)) { program in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 9) {
                            Text(programTimeRange(program))
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle(NexusTheme.accentLight)
                                .frame(width: 92, alignment: .leading)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(program.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                if !program.description.isEmpty {
                                    Text(program.description)
                                        .font(.caption)
                                        .foregroundStyle(NexusTheme.secondaryText)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 9))
                }
            } else if epgLoadingChannel == channel.id {
                HStack(spacing: 8) {
                    ProgressView().tint(NexusTheme.accentLight)
                    Text("Hämtar programinformation…")
                        .font(.caption)
                        .foregroundStyle(NexusTheme.secondaryText)
                }
                .padding(.vertical, 5)
            } else if epgByChannel[epgCacheKey(for: channel.id)] != nil {
                Text(epgErrors[epgCacheKey(for: channel.id)].map { "Programguiden kunde inte hämtas: \($0)" } ?? "Leverantören har inte lämnat någon programinformation för kanalen.")
                    .font(.caption)
                    .foregroundStyle(NexusTheme.secondaryText)
            } else {
                Text("Programinformationen hämtas när kanalen öppnas.")
                    .font(.caption)
                    .foregroundStyle(NexusTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(NexusTheme.elevatedSurface)
    }

    private func programTimeRange(_ program: XtreamEPGProgram) -> String {
        let start = program.startTimestamp?.formatted(date: .omitted, time: .shortened) ?? "--:--"
        let end = program.endTimestamp?.formatted(date: .omitted, time: .shortened) ?? "--:--"
        return "\(start)–\(end)"
    }

    @MainActor
    private func toggleEPG(_ channel: GuideChannel) async {
        if expandedEPGChannel == channel.id {
            expandedEPGChannel = nil
            epgRequestID = nil
            epgLoadingChannel = nil
            return
        }
        expandedEPGChannel = channel.id
        guard usingProviderData, let profile = activeProfile else { return }
        let cacheKey = epgCacheKey(for: channel.id)
        let cacheIsFresh = epgFetchedAt[cacheKey].map { Date().timeIntervalSince($0) < (epgErrors[cacheKey] == nil ? 300 : 60) } ?? false
        if cacheIsFresh { return }
        guard let password = try? KeychainCredentialStore.shared.password(
            provider: profile.provider, baseURL: profile.baseURL, username: profile.username
        ), !password.isEmpty else { return }
        let requestID = UUID()
        epgRequestID = requestID
        epgLoadingChannel = channel.id
        let configuration = ProviderConnectionConfiguration(provider: profile.provider, baseURL: profile.baseURL, username: profile.username)
        do {
            let programs = try await XtreamConnector().shortEPG(
                configuration: configuration, credentials: ProviderCredentials(password: password), streamID: channel.id
            )
            guard activeProfile?.baseURL == profile.baseURL, activeProfile?.username == profile.username else { return }
            epgByChannel[cacheKey] = programs
            epgErrors[cacheKey] = nil
            epgFetchedAt[cacheKey] = Date()
        } catch {
            guard activeProfile?.baseURL == profile.baseURL, activeProfile?.username == profile.username else { return }
            epgByChannel[cacheKey] = []
            epgErrors[cacheKey] = error.localizedDescription
            epgFetchedAt[cacheKey] = Date()
            loadMessage = "EPG kunde inte hämtas för \(channel.name): \(error.localizedDescription)"
        }
        if epgRequestID == requestID {
            epgLoadingChannel = nil
            epgRequestID = nil
        }
    }

    @MainActor
    private func loadProviderChannels() async {
        let requestID = UUID()
        providerLoadRequestID = requestID
        isLoading = true
        defer {
            if providerLoadRequestID == requestID {
                isLoading = false
                providerLoadRequestID = nil
            }
        }

        guard let profile = ProviderConnectionStore.shared.load().first(where: { $0.provider == .xtream }) else {
            activeProfile = nil
            favoriteIDs = [1, 3]
            liveCategories = []
            liveStreams = []
            loadMessage = "Ingen sparad Xtream-anslutning. Visar exempelkanaler."
            return
        }

        if activeProfile?.provider != profile.provider ||
            activeProfile?.baseURL != profile.baseURL ||
            activeProfile?.username != profile.username {
            epgByChannel = [:]
            epgFetchedAt = [:]
            epgErrors = [:]
            expandedEPGChannel = nil
            epgRequestID = nil
            epgLoadingChannel = nil
        }
        activeProfile = profile
        if let key = favoriteStorageKey {
            favoriteIDs = Set(UserDefaults.standard.array(forKey: key) as? [Int] ?? [])
        }
        guard let password = try? KeychainCredentialStore.shared.password(
            provider: profile.provider, baseURL: profile.baseURL, username: profile.username
        ), !password.isEmpty else {
            liveCategories = []
            liveStreams = []
            loadMessage = "Lösenord saknas i nyckelringen. Öppna Anslutningar och spara profilen igen."
            return
        }

        let configuration = ProviderConnectionConfiguration(provider: profile.provider, baseURL: profile.baseURL, username: profile.username)
        let credentials = ProviderCredentials(password: password)
        do {
            let connector = XtreamConnector()
            async let categories = connector.liveCategories(configuration: configuration, credentials: credentials)
            async let streams = connector.liveStreams(configuration: configuration, credentials: credentials)
            let loadedCategories = try await categories
            let loadedStreams = try await streams

            guard providerLoadRequestID == requestID,
                  activeProfile?.provider == profile.provider,
                  activeProfile?.baseURL == profile.baseURL,
                  activeProfile?.username == profile.username else { return }

            liveCategories = loadedCategories
            liveStreams = loadedStreams
            selectedGroup = "Alla"
            loadMessage = "Hämtade \(liveStreams.count) kanaler i \(liveCategories.count) kategorier från \(profile.displayName)."
        } catch {
            guard providerLoadRequestID == requestID,
                  activeProfile?.provider == profile.provider,
                  activeProfile?.baseURL == profile.baseURL,
                  activeProfile?.username == profile.username else { return }
            liveCategories = []
            liveStreams = []
            loadMessage = "Kunde inte hämta kanaler: \(error.localizedDescription)"
        }
    }

    private func toggleFavorite(_ id: Int) {
        if favoriteIDs.contains(id) { favoriteIDs.remove(id) }
        else { favoriteIDs.insert(id) }
        if let key = favoriteStorageKey {
            UserDefaults.standard.set(favoriteIDs.sorted(), forKey: key)
        }
    }
}
