import Foundation

/// Identifies a focused card: the item and the shelf it sits on, since one item can appear on several shelves.
public struct ShelfFocusID: Hashable, Sendable {
    public var shelfID: String
    public var itemID: String

    public init(shelfID: String, itemID: String) {
        self.shelfID = shelfID
        self.itemID = itemID
    }

    /// The shelf identifier used for items of the hero banner.
    public static let heroShelfID = "__hero__"

    /// A focus identifier for an item of the hero banner.
    public static func hero(_ itemID: String) -> ShelfFocusID {
        ShelfFocusID(shelfID: heroShelfID, itemID: itemID)
    }
}

/// A small state machine for focus on a shelf screen.
///
/// It remembers the last focused item of every shelf (so focus can return there), knows whether the
/// user is in the hero banner, browsing shelves or looking at a detail screen, and decides when the
/// hero banner may advance on its own. ``ShelfBrowser`` drives one for you; use it directly when you
/// build your own screen.
public struct ShelfFocusTracker: Hashable, Sendable {
    public enum Phase: Hashable, Sendable {
        /// Nothing on the screen is focused.
        case idle
        /// A button of the hero banner is focused.
        case hero
        /// A card on a shelf is focused.
        case browsing
        /// An item was selected and its detail is on screen.
        case presenting
    }

    public enum Event: Hashable, Sendable {
        /// A card gained focus.
        case focusItem(ShelfFocusID)
        /// The focused card lost focus.
        case leaveItem
        /// A hero banner button gained focus.
        case focusHero
        /// The hero banner lost focus.
        case leaveHero
        /// A card or hero item was chosen.
        case select(ShelfFocusID)
        /// The detail screen was closed.
        case dismiss
    }

    public private(set) var phase: Phase = .idle
    /// The card that has focus, or had it when a detail screen opened.
    public private(set) var current: ShelfFocusID?
    /// The item whose detail is on screen.
    public private(set) var selected: ShelfFocusID?
    private var lastItemByShelf: [String: String] = [:]

    public init() {}

    /// Applies `event` and returns the new phase.
    @discardableResult
    public mutating func handle(_ event: Event) -> Phase {
        switch event {
        case .focusItem(let id):
            current = id
            lastItemByShelf[id.shelfID] = id.itemID
            selected = nil
            phase = .browsing
        case .leaveItem:
            switch phase {
            case .browsing:
                current = nil
                phase = .idle
            case .hero:
                current = nil
            case .idle, .presenting:
                break
            }
        case .focusHero:
            current = nil
            selected = nil
            phase = .hero
        case .leaveHero:
            if phase == .hero { phase = .idle }
        case .select(let id):
            current = id
            lastItemByShelf[id.shelfID] = id.itemID
            selected = id
            phase = .presenting
        case .dismiss:
            guard phase == .presenting else { break }
            selected = nil
            if let current, current.shelfID == ShelfFocusID.heroShelfID {
                phase = .hero
            } else {
                phase = current == nil ? .idle : .browsing
            }
        }
        return phase
    }

    /// The last item focused on `shelfID`, if any.
    public func remembered(in shelfID: String) -> String? {
        lastItemByShelf[shelfID]
    }

    /// Whether the hero banner may advance on its own: only while the user is at the top of the
    /// screen, never while they browse shelves further down or read a detail screen.
    public var allowsHeroAutoAdvance: Bool {
        phase == .idle || phase == .hero
    }
}
