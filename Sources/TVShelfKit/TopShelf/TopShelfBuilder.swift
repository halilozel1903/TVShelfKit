import Foundation

/// The image shape of a Top Shelf item.
public enum TopShelfImageShape: String, Hashable, Sendable {
    case poster
    case square
    case hdtv

    /// The shape that matches a shelf layout: portrait layouts become posters, landscape ones HDTV.
    public init(_ layout: ShelfLayout) {
        self = layout.isPortrait ? .poster : .hdtv
    }
}

/// The two Top Shelf carousel styles.
public enum TopShelfCarouselStyle: String, Hashable, Sendable {
    /// Large artwork with Play and More Info buttons.
    case actions
    /// Large artwork with a summary, genre and running time.
    case details
}

/// One Top Shelf item, described with plain values so it can be built and tested anywhere.
/// On tvOS, turn a whole ``TopShelfContent`` into TVServices objects with `makeTVTopShelfContent()`.
public struct TopShelfItem: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var imageShape: TopShelfImageShape
    public var imageURL: URL?
    /// 0...1 for items in progress, otherwise `nil`.
    public var playbackProgress: Double?
    /// Opens the item's detail screen when the item is selected.
    public var displayURL: URL?
    /// Starts playback when the Play/Pause button is pressed on the item.
    public var playURL: URL?
    /// Carousel only: a line above the title, such as "New Episode" or "32m left".
    public var contextTitle: String?
    /// Carousel only.
    public var summary: String?
    /// Carousel only.
    public var genre: String?
    /// Carousel only: running time in seconds.
    public var duration: TimeInterval?

    public init(
        id: String,
        title: String,
        imageShape: TopShelfImageShape = .poster,
        imageURL: URL? = nil,
        playbackProgress: Double? = nil,
        displayURL: URL? = nil,
        playURL: URL? = nil,
        contextTitle: String? = nil,
        summary: String? = nil,
        genre: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.title = title
        self.imageShape = imageShape
        self.imageURL = imageURL
        self.playbackProgress = PlaybackProgress.clamp(playbackProgress)
        self.displayURL = displayURL
        self.playURL = playURL
        self.contextTitle = contextTitle
        self.summary = summary
        self.genre = genre
        self.duration = duration
    }
}

/// A titled row of Top Shelf items.
public struct TopShelfSection: Hashable, Sendable {
    public var title: String?
    public var items: [TopShelfItem]

    public init(title: String?, items: [TopShelfItem]) {
        self.title = title
        self.items = items
    }
}

/// What the Top Shelf shows: rows of items, or one large carousel.
public enum TopShelfContent: Hashable, Sendable {
    case sectioned([TopShelfSection])
    case carousel(TopShelfCarouselStyle, [TopShelfItem])

    /// Every item, in order.
    public var allItems: [TopShelfItem] {
        switch self {
        case .sectioned(let sections): sections.flatMap(\.items)
        case .carousel(_, let items): items
        }
    }

    /// `true` when there is nothing to show; return `nil` from your content provider then.
    public var isEmpty: Bool {
        allItems.isEmpty
    }
}

/// Builds Top Shelf content from your shelves.
///
/// ```swift
/// let builder = TopShelfBuilder(urlScheme: "lumen") { item, shape in
///     URL(string: "https://img.example.com/\(item.id)/\(shape.rawValue).jpg")
/// }
/// let content = builder.sectioned([continueWatching, trending])
/// ```
///
/// It drops empty shelves, finished items from Continue Watching and duplicates, limits the number of
/// sections and items, and gives every item display and play deep links (see ``ShelfDeepLink``).
public struct TopShelfBuilder: Sendable {
    /// The URL scheme of your app, used for the deep links.
    public var urlScheme: String
    public var maxSections: Int
    public var maxItemsPerSection: Int
    public var maxCarouselItems: Int
    /// Returns the image for an item in a given shape.
    public var imageURL: @Sendable (ShelfItem, TopShelfImageShape) -> URL?

    public init(
        urlScheme: String,
        maxSections: Int = 5,
        maxItemsPerSection: Int = 12,
        maxCarouselItems: Int = 8,
        imageURL: @escaping @Sendable (ShelfItem, TopShelfImageShape) -> URL? = { _, _ in nil }
    ) {
        self.urlScheme = urlScheme
        self.maxSections = max(0, maxSections)
        self.maxItemsPerSection = max(0, maxItemsPerSection)
        self.maxCarouselItems = max(0, maxCarouselItems)
        self.imageURL = imageURL
    }

    /// A Top Shelf item for `item`.
    public func item(for item: ShelfItem, shape: TopShelfImageShape) -> TopShelfItem {
        let inProgress = item.isInProgress
        return TopShelfItem(
            id: item.id,
            title: item.title,
            imageShape: shape,
            imageURL: imageURL(item, shape),
            playbackProgress: inProgress ? item.progress : nil,
            displayURL: ShelfDeepLink(action: .display, itemID: item.id).url(scheme: urlScheme),
            playURL: ShelfDeepLink(action: .play, itemID: item.id).url(scheme: urlScheme),
            contextTitle: inProgress ? item.remainingText : item.badge,
            summary: item.summary,
            genre: item.genres.first,
            duration: item.runtime
        )
    }

    /// Rows for the sectioned Top Shelf style, one per non-empty shelf, in order.
    public func sectioned(_ shelves: [Shelf]) -> TopShelfContent {
        var sections: [TopShelfSection] = []
        for shelf in shelves where sections.count < maxSections {
            let shape = TopShelfImageShape(shelf.layout)
            let candidates = shelf.layout == .continueWatching ? shelf.items.filter(\.isInProgress) : shelf.items
            let items = Self.unique(candidates).prefix(maxItemsPerSection).map { item(for: $0, shape: shape) }
            guard !items.isEmpty else { continue }
            sections.append(TopShelfSection(title: shelf.title, items: items))
        }
        return .sectioned(sections)
    }

    /// A carousel of the first unique `items`, using HDTV artwork.
    public func carousel(_ items: [ShelfItem], style: TopShelfCarouselStyle = .actions) -> TopShelfContent {
        let items = Self.unique(items).prefix(maxCarouselItems).map { item(for: $0, shape: .hdtv) }
        return .carousel(style, items)
    }

    private static func unique(_ items: [ShelfItem]) -> [ShelfItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }
}
