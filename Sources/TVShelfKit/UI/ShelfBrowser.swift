import SwiftUI

/// A complete streaming home screen: a hero banner on top and focus-driven shelves below.
///
/// ```swift
/// ShelfBrowser(hero: featured, shelves: shelves) { item in
///     selection = item
/// }
/// ```
///
/// The browser remembers the last focused card of every shelf and returns to it when focus comes
/// back to that shelf, pauses the hero banner while you browse further down, and can start with a
/// specific card focused.
public struct ShelfBrowser<Artwork: View>: View {
    public var hero: [ShelfItem]
    public var shelves: [Shelf]
    public var initialFocus: ShelfFocusID?
    public var heroInterval: Duration
    public var heroAutoAdvances: Bool
    public var showsTitles: Bool
    private let onSelect: (ShelfItem) -> Void
    private let onPlay: ((ShelfItem) -> Void)?
    private let onFocusChange: ((ShelfItem?) -> Void)?
    private let artwork: (ShelfItem, ShelfArtworkSlot) -> Artwork

    @FocusState private var focus: ShelfFocusID?
    @State private var tracker = ShelfFocusTracker()
    @Environment(\.shelfMetrics) private var metrics

    /// - Parameters:
    ///   - hero: Items for the hero banner. An empty array hides the banner.
    ///   - shelves: The rows below the banner. Empty shelves are skipped.
    ///   - initialFocus: A card to focus when the screen appears.
    ///   - heroInterval: How long each hero item stays.
    ///   - heroAutoAdvances: `false` keeps the hero banner on its first item.
    ///   - showsTitles: Draws titles under the cards.
    ///   - onPlay: Called by the hero's Play button. Defaults to `onSelect`.
    ///   - onFocusChange: Called with the focused card's item, or `nil` when no card is focused.
    ///   - artwork: The image for an item in a slot: the hero banner or a card of a given layout.
    ///   - onSelect: Called when a card or the hero's More Info button is selected.
    public init(
        hero: [ShelfItem] = [],
        shelves: [Shelf],
        initialFocus: ShelfFocusID? = nil,
        heroInterval: Duration = .seconds(8),
        heroAutoAdvances: Bool = true,
        showsTitles: Bool = true,
        onPlay: ((ShelfItem) -> Void)? = nil,
        onFocusChange: ((ShelfItem?) -> Void)? = nil,
        @ViewBuilder artwork: @escaping (ShelfItem, ShelfArtworkSlot) -> Artwork,
        onSelect: @escaping (ShelfItem) -> Void
    ) {
        self.hero = hero
        self.shelves = shelves
        self.initialFocus = initialFocus
        self.heroInterval = heroInterval
        self.heroAutoAdvances = heroAutoAdvances
        self.showsTitles = showsTitles
        self.onPlay = onPlay
        self.onFocusChange = onFocusChange
        self.artwork = artwork
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: metrics.rowSpacing * 0.4) {
                if !hero.isEmpty {
                    HeroBanner(
                        items: hero,
                        interval: heroInterval,
                        autoAdvances: heroAutoAdvances,
                        isPaused: !tracker.allowsHeroAutoAdvance,
                        onPlay: { item in (onPlay ?? onSelect)(item) },
                        onInfo: { item in select(item, focusID: .hero(item.id)) },
                        onFocusChange: { isFocused in
                            tracker.handle(isFocused ? ShelfFocusTracker.Event.focusHero : ShelfFocusTracker.Event.leaveHero)
                        },
                        artwork: { item in artwork(item, .hero) }
                    )
                }
                ForEach(shelves.filter { !$0.items.isEmpty }) { shelf in
                    ShelfRow(
                        shelf: shelf,
                        showsTitles: showsTitles,
                        onSelect: { item in select(item, focusID: ShelfFocusID(shelfID: shelf.id, itemID: item.id)) },
                        artwork: { item, layout in artwork(item, .card(layout)) }
                    )
                    .focus($focus, remembering: tracker.remembered(in: shelf.id))
                }
            }
            .padding(.bottom, metrics.rowSpacing)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .modifier(DefaultShelfFocusModifier(binding: $focus, id: initialFocus, userInitiated: false))
        .task {
            guard let initialFocus else { return }
            // Give the focus engine a moment to settle on the first screen before moving focus.
            try? await Task.sleep(for: .milliseconds(400))
            focus = initialFocus
        }
        .onChange(of: focus) { _, newValue in
            if let newValue {
                tracker.handle(.focusItem(newValue))
            } else {
                tracker.handle(.leaveItem)
            }
            onFocusChange?(newValue.flatMap { item(for: $0) })
        }
    }

    private func select(_ item: ShelfItem, focusID: ShelfFocusID) {
        tracker.handle(.select(focusID))
        onSelect(item)
    }

    private func item(for id: ShelfFocusID) -> ShelfItem? {
        shelves.first { $0.id == id.shelfID }?.items.first { $0.id == id.itemID }
    }
}

extension ShelfBrowser where Artwork == ShelfPlaceholderArtwork {
    /// A browser with generated placeholder artwork.
    public init(
        hero: [ShelfItem] = [],
        shelves: [Shelf],
        initialFocus: ShelfFocusID? = nil,
        heroInterval: Duration = .seconds(8),
        heroAutoAdvances: Bool = true,
        showsTitles: Bool = true,
        onPlay: ((ShelfItem) -> Void)? = nil,
        onFocusChange: ((ShelfItem?) -> Void)? = nil,
        onSelect: @escaping (ShelfItem) -> Void
    ) {
        self.init(
            hero: hero,
            shelves: shelves,
            initialFocus: initialFocus,
            heroInterval: heroInterval,
            heroAutoAdvances: heroAutoAdvances,
            showsTitles: showsTitles,
            onPlay: onPlay,
            onFocusChange: onFocusChange,
            artwork: { item, slot in ShelfPlaceholderArtwork(item: item, slot: slot) },
            onSelect: onSelect
        )
    }
}
