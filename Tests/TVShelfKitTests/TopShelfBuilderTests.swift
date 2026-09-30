import Foundation
import Testing
@testable import TVShelfKit

@Suite("TopShelfBuilder")
struct TopShelfBuilderTests {
    private let builder = TopShelfBuilder(urlScheme: "lumen", maxSections: 2, maxItemsPerSection: 3, maxCarouselItems: 2) { item, shape in
        URL(string: "https://img.example.com/\(item.id)-\(shape.rawValue).jpg")
    }

    private func items(_ prefix: String, count: Int) -> [ShelfItem] {
        (1...count).map { ShelfItem(id: "\(prefix)\($0)", title: "\(prefix.uppercased()) \($0)") }
    }

    @Test func itemCarriesImageLinksAndProgress() {
        let source = ShelfItem(
            id: "midnight-relay",
            title: "Midnight Relay",
            summary: "A courier race.",
            genres: ["Thriller", "Drama"],
            runtime: 3_120,
            badge: "New",
            progress: 0.5
        )
        let item = builder.item(for: source, shape: .hdtv)
        #expect(item.id == "midnight-relay")
        #expect(item.title == "Midnight Relay")
        #expect(item.imageShape == .hdtv)
        #expect(item.imageURL?.absoluteString == "https://img.example.com/midnight-relay-hdtv.jpg")
        #expect(item.playbackProgress == 0.5)
        #expect(item.displayURL?.absoluteString == "lumen://display?id=midnight-relay")
        #expect(item.playURL?.absoluteString == "lumen://play?id=midnight-relay")
        #expect(item.contextTitle == "26m left")
        #expect(item.genre == "Thriller")
        #expect(item.duration == 3_120)
        #expect(item.summary == "A courier race.")
    }

    @Test func notStartedItemsHaveNoProgressAndShowTheirBadge() {
        let item = builder.item(for: ShelfItem(id: "a", title: "A", badge: "New", progress: 0), shape: .poster)
        #expect(item.playbackProgress == nil)
        #expect(item.contextTitle == "New")
    }

    @Test func sectionedSkipsEmptyShelvesAndLimitsCounts() {
        let shelves = [
            Shelf(id: "empty", title: "Empty", items: []),
            Shelf(id: "trending", title: "Trending", layout: .poster, items: items("t", count: 5)),
            Shelf(id: "new", title: "New Episodes", layout: .landscape, items: items("n", count: 2)),
            Shelf(id: "more", title: "More", items: items("m", count: 2)),
        ]
        let content = builder.sectioned(shelves)
        guard case .sectioned(let sections) = content else {
            Issue.record("Expected sectioned content")
            return
        }
        #expect(sections.map(\.title) == ["Trending", "New Episodes"])
        #expect(sections[0].items.map(\.id) == ["t1", "t2", "t3"])
        #expect(sections[0].items.allSatisfy { $0.imageShape == .poster })
        #expect(sections[1].items.allSatisfy { $0.imageShape == .hdtv })
        #expect(content.allItems.count == 5)
    }

    @Test func continueWatchingDropsFinishedAndUnstartedItems() {
        let shelf = Shelf(id: "cw", title: "Continue Watching", layout: .continueWatching, items: [
            ShelfItem(id: "done", title: "Done", progress: 0.99),
            ShelfItem(id: "half", title: "Half", progress: 0.5),
            ShelfItem(id: "fresh", title: "Fresh"),
        ])
        let content = builder.sectioned([shelf])
        #expect(content.allItems.map(\.id) == ["half"])
        #expect(content.allItems.first?.playbackProgress == 0.5)
    }

    @Test func duplicatesAreRemoved() {
        let duplicate = ShelfItem(id: "same", title: "Same")
        let content = builder.sectioned([Shelf(id: "s", title: "S", items: [duplicate, duplicate, ShelfItem(id: "other", title: "Other")])])
        #expect(content.allItems.map(\.id) == ["same", "other"])
    }

    @Test func emptyInputGivesEmptyContent() {
        #expect(builder.sectioned([]).isEmpty)
        #expect(builder.sectioned([Shelf(id: "e", title: "E", items: [])]) == .sectioned([]))
        #expect(builder.carousel([]).isEmpty)
    }

    @Test func carouselUsesHDTVArtworkAndLimit() {
        let content = builder.carousel(items("c", count: 4), style: .details)
        guard case .carousel(let style, let carouselItems) = content else {
            Issue.record("Expected carousel content")
            return
        }
        #expect(style == .details)
        #expect(carouselItems.map(\.id) == ["c1", "c2"])
        #expect(carouselItems.allSatisfy { $0.imageShape == .hdtv })
    }

    @Test func invalidSchemeGivesNoLinks() {
        let broken = TopShelfBuilder(urlScheme: "not a scheme")
        let item = broken.item(for: ShelfItem(id: "a", title: "A"), shape: .poster)
        #expect(item.displayURL == nil)
        #expect(item.playURL == nil)
        #expect(item.imageURL == nil)
    }

    @Test func imageShapeFollowsLayout() {
        #expect(TopShelfImageShape(.poster) == .poster)
        #expect(TopShelfImageShape(.ranked) == .poster)
        #expect(TopShelfImageShape(.landscape) == .hdtv)
        #expect(TopShelfImageShape(.continueWatching) == .hdtv)
    }
}

@Suite("ShelfDeepLink")
struct ShelfDeepLinkTests {
    @Test func buildsURLs() {
        let link = ShelfDeepLink(action: .play, itemID: "show one&two=+")
        #expect(link.url(scheme: "lumen")?.absoluteString == "lumen://play?id=show%20one%26two%3D%2B")
        #expect(ShelfDeepLink(action: .display, itemID: "42").url(scheme: "my-app.tv")?.absoluteString == "my-app.tv://display?id=42")
    }

    @Test(arguments: ShelfDeepLink.Action.allCases)
    func roundTrips(action: ShelfDeepLink.Action) throws {
        let link = ShelfDeepLink(action: action, itemID: "série 7/8 & more")
        let url = try #require(link.url(scheme: "lumen"))
        #expect(ShelfDeepLink(url: url, scheme: "lumen") == link)
        #expect(ShelfDeepLink(url: url) == link)
    }

    @Test func rejectsForeignOrBrokenURLs() throws {
        let other = try #require(URL(string: "other://play?id=1"))
        #expect(ShelfDeepLink(url: other, scheme: "lumen") == nil)
        let unknownAction = try #require(URL(string: "lumen://delete?id=1"))
        #expect(ShelfDeepLink(url: unknownAction) == nil)
        let missingID = try #require(URL(string: "lumen://play"))
        #expect(ShelfDeepLink(url: missingID) == nil)
        let emptyID = try #require(URL(string: "lumen://play?id="))
        #expect(ShelfDeepLink(url: emptyID) == nil)
    }

    @Test func schemeIsCaseInsensitive() throws {
        let url = try #require(URL(string: "LUMEN://PLAY?id=7"))
        #expect(ShelfDeepLink(url: url, scheme: "lumen") == ShelfDeepLink(action: .play, itemID: "7"))
    }

    @Test func validatesSchemes() {
        #expect(ShelfDeepLink.isValidScheme("lumen"))
        #expect(ShelfDeepLink.isValidScheme("my-app.tv+1"))
        #expect(!ShelfDeepLink.isValidScheme(""))
        #expect(!ShelfDeepLink.isValidScheme("1app"))
        #expect(!ShelfDeepLink.isValidScheme("my app"))
        #expect(!ShelfDeepLink.isValidScheme("émission"))
        #expect(ShelfDeepLink(action: .play, itemID: "").url(scheme: "lumen") == nil)
    }
}
