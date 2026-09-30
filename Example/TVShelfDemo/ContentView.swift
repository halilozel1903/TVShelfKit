import SwiftUI
import TVShelfKit

struct ContentView: View {
    let scene: ScreenshotScene?
    @State private var presented: ShelfItem?

    var body: some View {
        Group {
            if scene == .detail {
                DetailView(item: SampleCatalog.detailItem, related: SampleCatalog.because) {}
            } else {
                HomeView(
                    initialFocus: scene?.initialFocus,
                    // Screenshots keep the hero on its first item so every capture looks the same.
                    heroAutoAdvances: scene == nil
                ) { item in
                    presented = item
                }
            }
        }
        .fullScreenCover(item: $presented) { item in
            DetailView(item: item, related: SampleCatalog.because) {
                presented = nil
            }
        }
    }
}

struct HomeView: View {
    var initialFocus: ShelfFocusID?
    var heroAutoAdvances: Bool
    var onSelect: (ShelfItem) -> Void

    var body: some View {
        // The bar sits above the scroll view, so rows scrolled up never slide under it.
        VStack(spacing: 0) {
            TopBar()
            ShelfBrowser(
                hero: SampleCatalog.featured,
                shelves: SampleCatalog.shelves,
                initialFocus: initialFocus,
                heroAutoAdvances: heroAutoAdvances,
                onSelect: onSelect
            )
        }
        .background(Color(white: 0.06))
        .ignoresSafeArea()
    }
}

/// A non-interactive brand bar in the style of a streaming app. "Lumen" is a made-up service.
private struct TopBar: View {
    var body: some View {
        HStack(spacing: 48) {
            HStack(spacing: 12) {
                Image(systemName: "play.tv.fill")
                Text("LUMEN")
                    .tracking(6)
            }
            .font(.system(size: 34, weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 1, green: 0.32, blue: 0.3))
            ForEach(["Home", "Movies", "Series", "My List"], id: \.self) { tab in
                Text(tab)
                    .font(.system(size: 26, weight: tab == "Home" ? Font.Weight.bold : Font.Weight.medium))
                    .foregroundStyle(tab == "Home" ? Color.white : Color.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.horizontal, 80)
        .padding(.top, 50)
        .padding(.bottom, 24)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
