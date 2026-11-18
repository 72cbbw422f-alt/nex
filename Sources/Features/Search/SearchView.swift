import SwiftUI

struct SearchView: View {
    @State private var query = ""

    private var results: [NEXUSMediaFixture] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }
        return NEXUSMediaFixture.all.filter {
            $0.title.localizedCaseInsensitiveContains(normalizedQuery) ||
            $0.subtitle.localizedCaseInsensitiveContains(normalizedQuery)
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

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                                MediaDetailView(title: result.title, subtitle: result.subtitle, seed: result.artworkSeed)
                            } label: {
                                HStack(spacing: 13) {
                                    RoundedRectangle(cornerRadius: 9)
                                        .fill(NexusTheme.posterGradient(seed: result.artworkSeed))
                                        .frame(width: 66, height: 88)
                                        .overlay(Image(systemName: result.kind == .series ? "tv" : "film").foregroundStyle(.white.opacity(0.8)))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(result.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                        Text(result.subtitle)
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
