import CoreGraphics
import Foundation

/// How the cards of a shelf are drawn.
public enum ShelfLayout: String, Hashable, Sendable, CaseIterable {
    /// Portrait 2:3 posters.
    case poster
    /// Landscape 16:9 cards.
    case landscape
    /// Landscape cards with a progress bar and the time left.
    case continueWatching
    /// Posters with a large rank number beside them, for a "Top 10" row.
    case ranked

    /// Width divided by height.
    public var aspectRatio: Double {
        switch self {
        case .poster, .ranked: 2.0 / 3.0
        case .landscape, .continueWatching: 16.0 / 9.0
        }
    }

    /// `true` for layouts that use ``ShelfMetrics/posterHeight``.
    public var isPortrait: Bool {
        aspectRatio < 1
    }
}

/// A titled row of items.
public struct Shelf: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var layout: ShelfLayout
    public var items: [ShelfItem]

    public init(id: String, title: String, subtitle: String? = nil, layout: ShelfLayout = .poster, items: [ShelfItem]) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.layout = layout
        self.items = items
    }

    /// A "Continue Watching" shelf with the items that are started but not finished, in their original order.
    public static func continueWatching(
        id: String = "continue-watching",
        title: String = "Continue Watching",
        from items: [ShelfItem]
    ) -> Shelf {
        Shelf(id: id, title: title, layout: .continueWatching, items: items.filter(\.isInProgress))
    }
}

/// Sizes and spacing for shelves. Set them for a whole screen with `.shelfMetrics(_:)`.
public struct ShelfMetrics: Hashable, Sendable {
    /// Height of portrait cards (`.poster`, `.ranked`).
    public var posterHeight: CGFloat
    /// Height of landscape cards (`.landscape`, `.continueWatching`).
    public var landscapeHeight: CGFloat
    /// Space between cards in a row.
    public var itemSpacing: CGFloat
    /// Space between rows.
    public var rowSpacing: CGFloat
    /// Leading and trailing inset of rows and headers.
    public var horizontalInset: CGFloat
    /// Corner radius of cards.
    public var cornerRadius: CGFloat
    /// Scale of a focused card.
    public var focusedScale: CGFloat
    /// Height of the hero banner.
    public var heroHeight: CGFloat
    /// How far the artwork inside a card slides as the card moves across the screen, in points. 0 turns parallax off.
    public var parallaxAmount: CGFloat
    /// The width parallax is measured against, usually the screen width.
    public var parallaxReferenceWidth: CGFloat

    public init(
        posterHeight: CGFloat = 360,
        landscapeHeight: CGFloat = 220,
        itemSpacing: CGFloat = 40,
        rowSpacing: CGFloat = 50,
        horizontalInset: CGFloat = 80,
        cornerRadius: CGFloat = 16,
        focusedScale: CGFloat = 1.1,
        heroHeight: CGFloat = 640,
        parallaxAmount: CGFloat = 24,
        parallaxReferenceWidth: CGFloat = 1920
    ) {
        self.posterHeight = max(1, posterHeight)
        self.landscapeHeight = max(1, landscapeHeight)
        self.itemSpacing = max(0, itemSpacing)
        self.rowSpacing = max(0, rowSpacing)
        self.horizontalInset = max(0, horizontalInset)
        self.cornerRadius = max(0, cornerRadius)
        self.focusedScale = min(max(focusedScale, 1), 1.5)
        self.heroHeight = max(1, heroHeight)
        self.parallaxAmount = max(0, parallaxAmount)
        self.parallaxReferenceWidth = max(1, parallaxReferenceWidth)
    }

    /// Apple TV sizes, designed for a 1920 × 1080 point screen.
    public static let tv = ShelfMetrics()

    /// Smaller sizes for iPhone, iPad and Mac.
    public static let compact = ShelfMetrics(
        posterHeight: 180,
        landscapeHeight: 110,
        itemSpacing: 14,
        rowSpacing: 26,
        horizontalInset: 20,
        cornerRadius: 10,
        focusedScale: 1.05,
        heroHeight: 380,
        parallaxAmount: 10,
        parallaxReferenceWidth: 400
    )

    /// ``tv`` on tvOS, ``compact`` everywhere else.
    public static var platformDefault: ShelfMetrics {
        #if os(tvOS)
        return .tv
        #else
        return .compact
        #endif
    }

    /// The size of a card in `layout`.
    public func cardSize(for layout: ShelfLayout) -> CGSize {
        let height = layout.isPortrait ? posterHeight : landscapeHeight
        return CGSize(width: (height * layout.aspectRatio).rounded(), height: height)
    }

    /// Vertical room a row needs above and below its cards so a focused card and its shadow are not cut off.
    public func focusRoom(for layout: ShelfLayout) -> CGFloat {
        let height = cardSize(for: layout).height
        return (height * (focusedScale - 1) / 2).rounded() + 20
    }
}
