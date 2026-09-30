#if os(tvOS) && canImport(TVServices)
import TVServices

extension TopShelfContent {
    /// The TVServices content to return from `TVTopShelfContentProvider.loadTopShelfContent()`,
    /// or `nil` when there is nothing to show.
    ///
    /// ```swift
    /// final class ContentProvider: TVTopShelfContentProvider {
    ///     override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
    ///         let shelves = await Catalog.shared.homeShelves()
    ///         return TopShelfBuilder(urlScheme: "lumen").sectioned(shelves).makeTVTopShelfContent()
    ///     }
    /// }
    /// ```
    public func makeTVTopShelfContent() -> (any TVTopShelfContent)? {
        guard !isEmpty else { return nil }
        switch self {
        case .sectioned(let sections):
            let collections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = sections.map { section in
                let collection = TVTopShelfItemCollection(items: section.items.map { $0.makeSectionedItem() })
                collection.title = section.title
                return collection
            }
            return TVTopShelfSectionedContent(sections: collections)
        case .carousel(let style, let items):
            let carouselStyle: TVTopShelfCarouselContent.Style = style == .details ? .details : .actions
            return TVTopShelfCarouselContent(style: carouselStyle, items: items.map { $0.makeCarouselItem() })
        }
    }
}

extension TopShelfItem {
    /// A `TVTopShelfSectionedItem` with the title, image, progress and actions of this item.
    public func makeSectionedItem() -> TVTopShelfSectionedItem {
        let item = TVTopShelfSectionedItem(identifier: id)
        item.title = title
        switch imageShape {
        case .poster: item.imageShape = .poster
        case .square: item.imageShape = .square
        case .hdtv: item.imageShape = .hdtv
        }
        if let playbackProgress {
            item.playbackProgress = playbackProgress
        }
        applyCommonValues(to: item)
        return item
    }

    /// A `TVTopShelfCarouselItem` with the title, image, details and actions of this item.
    public func makeCarouselItem() -> TVTopShelfCarouselItem {
        let item = TVTopShelfCarouselItem(identifier: id)
        item.title = title
        item.contextTitle = contextTitle
        item.summary = summary
        item.genre = genre
        if let duration, duration.isFinite, duration > 0 {
            item.duration = duration
        }
        applyCommonValues(to: item)
        return item
    }

    private func applyCommonValues(to item: TVTopShelfItem) {
        if let imageURL {
            item.setImageURL(imageURL, for: .screenScale1x)
            item.setImageURL(imageURL, for: .screenScale2x)
        }
        if let displayURL {
            item.displayAction = TVTopShelfAction(url: displayURL)
        }
        if let playURL {
            item.playAction = TVTopShelfAction(url: playURL)
        }
    }
}
#endif
