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
            NavigationStack { HomeView() }
                .tabItem { Label("Hem", systemImage: "house.fill") }
            NavigationStack { MediaLibraryView(kind: .movies) }
                .tabItem { Label("Filmer", systemImage: "film") }
            NavigationStack { MediaLibraryView(kind: .series) }
                .tabItem { Label("Serier", systemImage: "rectangle.stack") }
            NavigationStack { LiveView() }
                .tabItem { Label("Live", systemImage: "dot.radiowaves.left.and.right") }
            NavigationStack { PlaceholderScreen(title: "Min lista", symbol: "bookmark", detail: "Allt du sparat på ett ställe.") }
                .tabItem { Label("Min lista", systemImage: "bookmark") }
        }
        .tint(NexusTheme.accentLight)
    }

    private var tvRoot: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Hem", systemImage: "house.fill") }
            NavigationStack { LiveView() }
                .tabItem { Label("Live TV", systemImage: "dot.radiowaves.left.and.right") }
            NavigationStack { MediaLibraryView(kind: .movies) }
                .tabItem { Label("Filmer", systemImage: "film") }
            NavigationStack { PlaceholderScreen(title: "Serier", symbol: "tv", detail: "Serier, säsonger och avsnitt.") }
                .tabItem { Label("Serier", systemImage: "rectangle.stack") }
            NavigationStack { PlaceholderScreen(title: "Min lista", symbol: "bookmark", detail: "Dina sparade filmer och serier.") }
                .tabItem { Label("Min lista", systemImage: "bookmark") }
        }
        .tint(NexusTheme.accentLight)
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
                .foregroundStyle(NexusTheme.accentLight)
            Text(title).font(.title2.bold()).foregroundStyle(.white)
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
