import SwiftUI

struct MediaDetailView: View {
    let title: String
    let subtitle: String
    let seed: Int

    private var isSeries: Bool { subtitle.localizedCaseInsensitiveContains("serie") }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                artworkHeader
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        metadataPill(isSeries ? "Serie" : "Film")
                        metadataPill(isSeries ? "3 säsonger" : "2024")
                        metadataPill(isSeries ? "8 avsnitt" : "2 h 46 min")
                        metadataPill("4K")
                    }
                    Text("8,5")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NexusTheme.accentLight)
                    Text("En berättelse fylld av starka karaktärer, oväntade vändningar och en värld värd att upptäcka. Metadata och beskrivning hämtas från dina anslutna katalogkällor när de är konfigurerade.")
                        .font(.subheadline)
                        .foregroundStyle(NexusTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        Button {} label: {
                            Label(isSeries ? "Spela S1 E1" : "Spela", systemImage: "play.fill")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(NexusTheme.accent, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        Button {} label: {
                            Label("Min lista", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(NexusTheme.surface, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)

                metadataSection
                if isSeries { episodesSection }
                castSection
                relatedSection
            }
            .padding(.bottom, 36)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var artworkHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(NexusTheme.posterGradient(seed: seed))
                .frame(height: 255)
            LinearGradient(colors: [.clear, NexusTheme.background], startPoint: .center, endPoint: .bottom)
            Text(title.uppercased())
                .font(.system(size: 27, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white)
                .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 12)
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Om")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                infoCell("GENRE", value: "Drama · Sci-Fi")
                infoCell("PREMIÄR", value: "2024")
                infoCell("UPPLÖSNING", value: "4K UHD")
                infoCell("LJUD", value: "Dolby Atmos")
                infoCell("UNDERtexter", value: "Svenska · Engelska")
                infoCell("KÄLLOR", value: "IPTV · Jellyfin")
            }
        }
        .padding(.horizontal, 18)
    }

    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Avsnitt")
            ForEach(1...4, id: \.self) { number in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(NexusTheme.posterGradient(seed: number))
                        .frame(width: 104, height: 64)
                        .overlay(Image(systemName: "play.fill").foregroundStyle(.white))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Avsnitt \(number)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Avsnittsbeskrivning och speltid visas här.")
                            .font(.caption)
                            .foregroundStyle(NexusTheme.secondaryText)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "play.circle")
                        .foregroundStyle(NexusTheme.accentLight)
                }
                .padding(10)
                .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 13))
            }
        }
        .padding(.horizontal, 18)
    }

    private var castSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Medverkande")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(["Huvudroll", "Skådespelare", "Regissör", "Manus"], id: \.self) { role in
                        VStack(alignment: .leading, spacing: 5) {
                            Circle()
                                .fill(NexusTheme.posterGradient(seed: role.count))
                                .frame(width: 62, height: 62)
                                .overlay(Image(systemName: "person.fill").foregroundStyle(.white.opacity(0.8)))
                            Text(role)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 78, alignment: .leading)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
    }

    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Relaterat")
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 11)
                        .fill(NexusTheme.posterGradient(seed: index + seed + 1))
                        .aspectRatio(2 / 3, contentMode: .fit)
                        .overlay(alignment: .bottomLeading) {
                            Text(["Liknande", "Samma genre", "Populärt"][index])
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(8)
                        }
                }
            }
        }
        .padding(.horizontal, 18)
    }

    private func sectionTitle(_ value: String) -> some View {
        Text(value)
            .font(.title3.bold())
            .foregroundStyle(.white)
    }

    private func metadataPill(_ value: String) -> some View {
        Text(value)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(NexusTheme.surface, in: Capsule())
            .foregroundStyle(.white)
    }

    private func infoCell(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(NexusTheme.secondaryText)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
