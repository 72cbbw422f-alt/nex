import SwiftUI

private struct HomeTitle: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let seed: Int
}

private struct LiveProgramme: Identifiable {
    let id: Int
    let channel: String
    let programme: String
    let time: String
    let progress: CGFloat
    let tint: Color
}

struct HomeView: View {
    private let titles = [
        HomeTitle(id: 1, title: "The Last of Us", subtitle: "Serie · S2 E4", seed: 0),
        HomeTitle(id: 2, title: "Fallout", subtitle: "Serie · S1 E2", seed: 1),
        HomeTitle(id: 3, title: "Dune: Part Two", subtitle: "Film · 2024", seed: 2),
        HomeTitle(id: 4, title: "House of the Dragon", subtitle: "Serie · S2", seed: 3)
    ]

    private let live = [
        LiveProgramme(id: 1, channel: "svt1", programme: "Aktuellt", time: "17:00 – 18:00", progress: 0.68, tint: .cyan),
        LiveProgramme(id: 2, channel: "TV4", programme: "Nyhetsmorgon", time: "08:55 – 11:30", progress: 0.42, tint: .red),
        LiveProgramme(id: 3, channel: "Kanal 5", programme: "Gränsbevakarna", time: "17:10 – 18:00", progress: 0.54, tint: .purple),
        LiveProgramme(id: 4, channel: "Discovery+", programme: "Gold Rush", time: "17:00 – 18:00", progress: 0.31, tint: .blue)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                hero
                liveShelf
                titleShelf(title: "Fortsätt titta", subtitle: "Fortsätt där du slutade", items: Array(titles.prefix(2)))
                titleShelf(title: "Populärt på NEXUS", subtitle: "Utvalt från dina anslutna källor", items: titles)
            }
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("NEXUS")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink { SearchView() } label: { Image(systemName: "magnifyingglass") }
                Button {} label: { Image(systemName: "bell") }
            }
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(red: 0.27, green: 0.20, blue: 0.42), Color(red: 0.055, green: 0.07, blue: 0.13), NexusTheme.background], startPoint: .topTrailing, endPoint: .bottomLeading)
                )
            Circle()
                .fill(NexusTheme.accent.opacity(0.18))
                .frame(width: 230, height: 230)
                .blur(radius: 65)
                .offset(x: 170, y: -35)
            VStack(alignment: .leading, spacing: 11) {
                Label("UTVALT PÅ NEXUS", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(NexusTheme.accentLight)
                Text("DUNE")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(5)
                    .foregroundStyle(.white)
                Text("PART TWO  ·  2024  ·  2 h 46 min")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                Text("Paul Atreides förenar krafterna med fremen i kampen om Arrakis.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
                    .frame(maxWidth: 440, alignment: .leading)
                HStack(spacing: 10) {
                    Button {} label: {
                        Label("Spela", systemImage: "play.fill")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(NexusTheme.accent, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    Button {} label: {
                        Label("Min lista", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 11)
                            .background(.white.opacity(0.12), in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
        }
        .frame(minHeight: 255)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(NexusTheme.border, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var liveShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("LIVE NU", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline.bold())
                    .foregroundStyle(NexusTheme.accentLight)
                Spacer()
                Button("Visa alla") {}
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NexusTheme.secondaryText)
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 11) {
                    ForEach(live) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .center) {
                                Text(item.channel)
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(item.tint)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text("LIVE")
                                    .font(.system(size: 8, weight: .heavy))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.red, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                            Text(item.programme)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(item.time)
                                .font(.caption2)
                                .foregroundStyle(NexusTheme.secondaryText)
                            GeometryReader { proxy in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(.white.opacity(0.14))
                                    Capsule().fill(NexusTheme.accent).frame(width: proxy.size.width * item.progress)
                                }
                            }
                            .frame(height: 3)
                        }
                        .padding(12)
                        .frame(width: 148, alignment: .leading)
                        .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(NexusTheme.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func titleShelf(title: String, subtitle: String, items: [HomeTitle]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title3.bold()).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(NexusTheme.secondaryText)
            }
            .padding(.horizontal, 18)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 13) {
                    ForEach(items) { item in
                        NavigationLink {
                            MediaDetailView(title: item.title, subtitle: item.subtitle, seed: item.seed)
                        } label: {
                            PosterTile(title: item.title, subtitle: item.subtitle, seed: item.seed)
                                .frame(width: 126)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
}
