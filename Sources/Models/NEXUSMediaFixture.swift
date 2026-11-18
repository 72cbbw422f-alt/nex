import Foundation

/// Shared preview catalogue used by library and search until provider ingestion is implemented.
struct NEXUSMediaFixture: Identifiable {
    enum Kind {
        case movie
        case series
    }

    let id: Int
    let title: String
    let subtitle: String
    let artworkSeed: Int
    let kind: Kind

    static let all: [NEXUSMediaFixture] = [
        .init(id: 1, title: "Dune: Part Two", subtitle: "Film · 2024", artworkSeed: 2, kind: .movie),
        .init(id: 2, title: "Oppenheimer", subtitle: "Film · 2023", artworkSeed: 1, kind: .movie),
        .init(id: 3, title: "Arrival", subtitle: "Film · 2016", artworkSeed: 0, kind: .movie),
        .init(id: 4, title: "Blade Runner 2049", subtitle: "Film · 2017", artworkSeed: 3, kind: .movie),
        .init(id: 5, title: "The Last of Us", subtitle: "Serie · 2 säsonger", artworkSeed: 0, kind: .series),
        .init(id: 6, title: "Fallout", subtitle: "Serie · 1 säsong", artworkSeed: 1, kind: .series),
        .init(id: 7, title: "House of the Dragon", subtitle: "Serie · 2 säsonger", artworkSeed: 3, kind: .series),
        .init(id: 8, title: "Severance", subtitle: "Serie · 2 säsonger", artworkSeed: 2, kind: .series)
    ]
}
