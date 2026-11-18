import SwiftUI

enum MediaLibraryKind: Equatable {
    case movies
    case series

    var title: String { self == .movies ? "Filmer" : "Serier" }
    var emptyMessage: String { self == .movies ? "Inga filmer matchar sökningen." : "Inga serier matchar sökningen." }
}

private struct LibraryItem: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let seed: Int
}

struct MediaLibraryView: View {
    let kind: MediaLibraryKind
    @State private var searchText = ""

    private var items: [LibraryItem] {
        let all = kind == .movies
            ? [
                LibraryItem(id: 1, title: "Dune: Part Two", subtitle: "Film · 2024", seed: 2),
                LibraryItem(id: 2, title: "Oppenheimer", subtitle: "Film · 2023", seed: 1),
                LibraryItem(id: 3, title: "Arrival", subtitle: "Film · 2016", seed: 0),
                LibraryItem(id: 4, title: "Blade Runner 2049", subtitle: "Film · 2017", seed: 3)
            ]
            : [
                LibraryItem(id: 5, title: "The Last of Us", subtitle: "Serie · 2 säsonger", seed: 0),
                LibraryItem(id: 6, title: "Fallout", subtitle: "Serie · 1 säsong", seed: 1),
                LibraryItem(id: 7, title: "House of the Dragon", subtitle: "Serie · 2 säsonger", seed: 3),
                LibraryItem(id: 8, title: "Severance", subtitle: "Serie · 2 säsonger", seed: 2)
            ]
        guard !searchText.isEmpty else { return all }
        return all.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
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
                                MediaDetailView(title: item.title, subtitle: item.subtitle, seed: item.seed)
                            } label: {
                                PosterTile(title: item.title, subtitle: item.subtitle, seed: item.seed)
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
