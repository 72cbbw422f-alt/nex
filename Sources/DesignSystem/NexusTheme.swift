import SwiftUI

enum NexusTheme {
    static let background = Color(red: 0.018, green: 0.025, blue: 0.045)
    static let surface = Color(red: 0.055, green: 0.065, blue: 0.095)
    static let elevatedSurface = Color(red: 0.085, green: 0.095, blue: 0.135)
    static let accent = Color(red: 0.62, green: 0.30, blue: 0.98)
    static let accentLight = Color(red: 0.78, green: 0.55, blue: 1.0)
    static let secondaryText = Color(red: 0.66, green: 0.68, blue: 0.76)
    static let border = Color.white.opacity(0.10)

    static func posterGradient(seed: Int) -> LinearGradient {
        let palettes: [[Color]] = [
            [Color(red: 0.28, green: 0.20, blue: 0.48), Color(red: 0.035, green: 0.045, blue: 0.09)],
            [Color(red: 0.42, green: 0.20, blue: 0.32), Color(red: 0.055, green: 0.035, blue: 0.09)],
            [Color(red: 0.15, green: 0.30, blue: 0.40), Color(red: 0.025, green: 0.055, blue: 0.10)],
            [Color(red: 0.34, green: 0.22, blue: 0.48), Color(red: 0.045, green: 0.035, blue: 0.09)]
        ]
        let colors = palettes[abs(seed) % palettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
