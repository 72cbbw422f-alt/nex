import SwiftUI

enum NexusTheme {
    static let background = Color(red: 0.035, green: 0.047, blue: 0.071)
    static let surface = Color(red: 0.075, green: 0.090, blue: 0.125)
    static let elevatedSurface = Color(red: 0.105, green: 0.125, blue: 0.165)
    static let accent = Color(red: 0.73, green: 0.88, blue: 0.43)
    static let secondaryText = Color(red: 0.62, green: 0.67, blue: 0.75)

    static func posterGradient(seed: Int) -> LinearGradient {
        let palettes: [[Color]] = [
            [Color(red: 0.16, green: 0.28, blue: 0.39), Color(red: 0.04, green: 0.07, blue: 0.12)],
            [Color(red: 0.36, green: 0.22, blue: 0.24), Color(red: 0.08, green: 0.07, blue: 0.11)],
            [Color(red: 0.25, green: 0.31, blue: 0.23), Color(red: 0.06, green: 0.09, blue: 0.09)],
            [Color(red: 0.29, green: 0.25, blue: 0.40), Color(red: 0.07, green: 0.06, blue: 0.13)]
        ]
        let colors = palettes[abs(seed) % palettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
