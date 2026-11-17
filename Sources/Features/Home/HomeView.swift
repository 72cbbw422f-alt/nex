import SwiftUI

struct HomeView: View {
    private let picks: [(String, String, Int)] = [
        ("The Silent Sea", "Serie · 2024", 0),
        ("Northern Lights", "Film · 2023", 1),
        ("The Last Signal", "Film · 2025", 2),
        ("After Midnight", "Serie · 2022", 3)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                shelf(title: "Fortsätt titta", subtitle: "Där du slutade", items: picks)
                shelf(title: "Utvalt för dig", subtitle: "Från alla dina källor", items: Array(picks.reversed()))
            }
            .padding(.vertical, 24)
        }
        .background(NexusTheme.background.ignoresSafeArea())
        .navigationTitle("NEXUS")
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.29, blue: 0.38), NexusTheme.background],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
            VStack(alignment: .leading, spacing: 12) {
                Label("DIN STREAMINGVÄRLD", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(NexusTheme.accent)
                Text("Allt du vill se.\nPå ett ställe.")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Filmer, serier och live-TV från dina anslutna källor.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: {}) {
                    Label("Utforska biblioteket", systemImage: "arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(NexusTheme.accent, in: Capsule())
                        .foregroundStyle(NexusTheme.background)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
        }
        .frame(minHeight: 250)
        .padding(.horizontal, 20)
    }

    private func shelf(title: String, subtitle: String, items: [(String, String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(NexusTheme.secondaryText)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(Array(items.enumerated()), id: \.offset) { entry in
                        let item = entry.element
                        PosterTile(title: item.0, subtitle: item.1, seed: item.2)
                            .frame(width: 132)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
