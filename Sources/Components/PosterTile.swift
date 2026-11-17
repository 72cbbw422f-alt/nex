import SwiftUI

struct PosterTile: View {
    let title: String
    let subtitle: String
    let seed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(NexusTheme.posterGradient(seed: seed))
                VStack(alignment: .leading, spacing: 5) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                    Text(title.uppercased())
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                }
                .padding(12)
            }
            .aspectRatio(2 / 3, contentMode: .fit)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(NexusTheme.secondaryText)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}
