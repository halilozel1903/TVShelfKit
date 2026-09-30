import CoreGraphics
import Foundation
import Testing
@testable import TVShelfKit

@Suite("Shelf model")
struct ShelfModelTests {
    @Test func progressIsClamped() {
        var item = ShelfItem(id: "a", title: "A", progress: 1.7)
        #expect(item.progress == 1)
        item.progress = -0.2
        #expect(item.progress == 0)
        item.progress = .nan
        #expect(item.progress == nil)
    }

    @Test func metadataLine() {
        let item = ShelfItem(
            id: "a",
            title: "A",
            genres: ["Drama", "Mystery", "Thriller"],
            year: 2025,
            runtime: 6_720,
            contentRating: "TV-14"
        )
        #expect(item.metadataLine == "2025 · 1h 52m · TV-14 · Drama · Mystery")
        #expect(ShelfItem(id: "b", title: "B").metadataLine == "")
        #expect(ShelfItem(id: "c", title: "C", genres: ["", "Comedy"], runtime: 0).metadataLine == "Comedy")
    }

    @Test func remainingTextNeedsRuntimeAndProgress() {
        #expect(ShelfItem(id: "a", title: "A", runtime: 3_600, progress: 0.25).remainingText == "45m left")
        #expect(ShelfItem(id: "a", title: "A", runtime: 3_600).remainingText == nil)
        #expect(ShelfItem(id: "a", title: "A", progress: 0.5).remainingText == nil)
    }

    @Test func continueWatchingKeepsStartedUnfinishedItemsInOrder() {
        let items = [
            ShelfItem(id: "new", title: "New"),
            ShelfItem(id: "half", title: "Half", progress: 0.5),
            ShelfItem(id: "done", title: "Done", progress: 0.99),
            ShelfItem(id: "zero", title: "Zero", progress: 0),
            ShelfItem(id: "start", title: "Start", progress: 0.1),
        ]
        let shelf = Shelf.continueWatching(from: items)
        #expect(shelf.layout == .continueWatching)
        #expect(shelf.title == "Continue Watching")
        #expect(shelf.items.map(\.id) == ["half", "start"])
    }

    @Test func cardSizes() {
        let metrics = ShelfMetrics(posterHeight: 300, landscapeHeight: 180)
        #expect(metrics.cardSize(for: .poster) == CGSize(width: 200, height: 300))
        #expect(metrics.cardSize(for: .ranked) == CGSize(width: 200, height: 300))
        #expect(metrics.cardSize(for: .landscape) == CGSize(width: 320, height: 180))
        #expect(metrics.cardSize(for: .continueWatching) == CGSize(width: 320, height: 180))
    }

    @Test func metricsAreSanitized() {
        let metrics = ShelfMetrics(posterHeight: -10, itemSpacing: -4, focusedScale: 9, parallaxAmount: -3)
        #expect(metrics.posterHeight == 1)
        #expect(metrics.itemSpacing == 0)
        #expect(metrics.focusedScale == 1.5)
        #expect(metrics.parallaxAmount == 0)
    }

    @Test func focusRoomCoversTheScaledCard() {
        let metrics = ShelfMetrics(posterHeight: 400, focusedScale: 1.1)
        // (400 * 0.1 / 2) = 20, plus 20 for the shadow.
        #expect(metrics.focusRoom(for: .poster) == 40)
    }

    @Test func layoutShapes() {
        #expect(ShelfLayout.poster.isPortrait)
        #expect(ShelfLayout.ranked.isPortrait)
        #expect(!ShelfLayout.landscape.isPortrait)
        #expect(!ShelfLayout.continueWatching.isPortrait)
    }

    @Test func artworkPaletteIsDeterministicAndInRange() {
        let first = ArtworkPalette(seed: "northern-lights")
        let second = ArtworkPalette(seed: "northern-lights")
        let other = ArtworkPalette(seed: "paper-harbor")
        #expect(first == second)
        #expect(first != other)
        for seed in ["", "a", "b", "northern-lights", "🎬", String(repeating: "x", count: 500)] {
            let palette = ArtworkPalette(seed: seed)
            #expect((0..<1).contains(palette.hue))
            #expect((0..<1).contains(palette.secondaryHue))
            #expect((0.2...0.8).contains(palette.glowX))
            #expect((0.15...0.55).contains(palette.glowY))
            #expect((-18...18).contains(palette.tilt))
        }
    }

    @Test func fnv1aMatchesKnownVectors() {
        #expect(ArtworkPalette.fnv1a("") == 0xcbf2_9ce4_8422_2325)
        #expect(ArtworkPalette.fnv1a("a") == 0xaf63_dc4c_8601_ec8c)
    }
}
