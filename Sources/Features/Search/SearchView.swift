import SwiftUI

private struct SearchResult: Identifiable {
    let id: Int
    let title: String
    let detail: String
    let seed: Int
    let isSeries: Bool
}

struct SearchView: View {
    @State private var query = ""

    private let catalogue = [
        SearchResult(id: 1, title: "Dune: Part Two", detail: "Film · 2024", seed: 2, isSeries: false),
        SearchResult(id: 2, title: "The Last of Us", detail: "Serie · 2 säsonger", seed: 0, isSeries: true),
        SearchResult(id: 3, title: "Fallout", detail: "Serie · 1 säsong", seed: 1, isSeries: true),
        SearchResult(id: 4, title: "Oppenheimer", detail: "Film · 2023", seed: 3, isSeries: false),
        SearchResult(id: 5, title: "Severance", detail: "Serie · 2 säsonger", seed: 2, isSeries: true),
        SearchResult(id: 6, title: "Arrival", detail: "Film · 2016", seed: 0, isSeries: false)
    ]

    private var results: [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        return catalogue.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.detail.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sök")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Hitta filmer och serier i ditt NEXUS-bibliotek.")
                        .font(.subheadline)
                        .foregroundStyle(NexusTheme.secondaryText)
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NexusTheme.accentLight)
                    TextField("Sök efter titel…", text: $query)
                        .foregroundStyle(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(14)
                .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(NexusTheme.border, lineWidth: 1))

                if query.isEmpty {
                    ContentUnavailableView("Börja söka", systemImage: "sparkle.magnifyingglass", description: Text("Sök efter en film eller serie."))
                        .foregroundStyle(NexusTheme.secondaryText)
                        .padding(.top, 24)
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .foregroundStyle(NexusTheme.secondaryText)
                } else {
                    Text("\(results.count) träffar")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NexusTheme.secondaryText)
                    LazyVStack(spacing: 12) {
                        ForEach(results) { result in
                            NavigationLink {
                                MediaDetailView(title: result.title, subtitle: result.detail, seed: result.seed)
                            } label: {
                                HStack(spacing: 13) {
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(NexusTheme.posterGradient(seed: result.seed))
                                        .frame(width: 66, height: 88)
                                        .overlay(Image(systemName: result.isSeries ? "tv" : "film").foregroundStyle(.white.opacity(0.8)))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(result.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(result.detail)
                                            .font(.caption)
                                            .foregroundStyle(NexusTheme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(NexusTheme.secondaryText)
                                }
                                .padding(10)
                                .background(NexusTheme.surface, in: RoundedRectangle(cornerRadius: 13))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(18)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .navigationTitle("Sök")
    }
}
