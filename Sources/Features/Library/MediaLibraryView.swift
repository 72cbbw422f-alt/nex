import SwiftUI

enum MediaLibraryKind: Equatable {
    case movies
    case series

    var title: String { self == .movies ? "Filmer" : "Serier" }
    var emptyMessage: String { self == .movies ? "Inga filmer matchar sökningen." : "Inga serier matchar sökningen." }
    fileprivate var fixtureKind: NEXUSMediaFixture.Kind { self == .movies ? .movie : .series }
}

struct MediaLibraryView: View {
    let kind: MediaLibraryKind
    @State private var searchText = ""

    private var items: [NEXUSMediaFixture] {
        let matchingKind = NEXUSMediaFixture.all.filter { $0.kind == kind.fixtureKind }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return matchingKind }
        return matchingKind.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 112), spacing: 14, alignment: .top)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(kind.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text(kind == .movies ? "Hela ditt filmbibliotek på ett ställe." : "Fortsätt följa dina favoritserier.")
                        .font(.subheadline)
                        .foregroundStyle(NexusTheme.secondaryText)
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NexusTheme.secondaryText)
                    TextField("Sök i \(kind.title.lowercased())", text: $searchText)
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(NexusTheme.border, lineWidth: 1))

                if items.isEmpty {
                    ContentUnavailableView(kind.emptyMessage, systemImage: "magnifyingglass")
                        .foregroundStyle(NexusTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 28)
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                        ForEach(items) { item in
                            NavigationLink {
                                MediaDetailView(title: item.title, subtitle: item.subtitle, seed: item.artworkSeed)
                            } label: {
                                PosterTile(title: item.title, subtitle: item.subtitle, seed: item.artworkSeed)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .navigationTitle(kind.title)
    }
}
