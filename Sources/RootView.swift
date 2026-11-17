import SwiftUI

struct RootView: View {
    var body: some View {
        #if os(tvOS)
        tvRoot
        #else
        mobileRoot
        #endif
    }

    private var mobileRoot: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Hem", systemImage: "house") }

            NavigationStack {
                PlaceholderScreen(title: "Upptäck", symbol: "safari", detail: "Ett gemensamt bibliotek från alla anslutna källor.")
            }
            .tabItem { Label("Upptäck", systemImage: "safari") }

            NavigationStack {
                PlaceholderScreen(title: "Live-TV", symbol: "tv", detail: "Dina kanaler och din programguide samlas här.")
            }
            .tabItem { Label("Live-TV", systemImage: "tv") }

            NavigationStack {
                PlaceholderScreen(title: "Sök", symbol: "magnifyingglass", detail: "Sök efter filmer och serier i alla källor.")
            }
            .tabItem { Label("Sök", systemImage: "magnifyingglass") }

            NavigationStack {
                PlaceholderScreen(title: "Inställningar", symbol: "gearshape", detail: "Anslutningar, uppspelning och utseende.")
            }
            .tabItem { Label("Inställningar", systemImage: "gearshape") }
        }
        .tint(NexusTheme.accent)
    }

    private var tvRoot: some View {
        NavigationStack {
            HomeView()
        }
        .tint(NexusTheme.accent)
    }
}

private struct PlaceholderScreen: View {
    let title: String
    let symbol: String
    let detail: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(NexusTheme.accent)
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(detail)
                .font(.body)
                .foregroundStyle(NexusTheme.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NexusTheme.background.ignoresSafeArea())
        .navigationTitle(title)
    }
}
