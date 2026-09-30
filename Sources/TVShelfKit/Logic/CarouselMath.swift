import Foundation

/// Index and paging math for carousels and rows. Every function is total: empty collections and
/// out-of-range indices never trap.
public enum CarouselMath {
    /// `index` wrapped into `0..<count`, so -1 is the last item. Returns 0 when `count` is 0 or less.
    public static func wrapped(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let remainder = index % count
        return remainder >= 0 ? remainder : remainder + count
    }

    /// `index` limited to `0..<count`. Returns 0 when `count` is 0 or less.
    public static func clamped(_ index: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(max(index, 0), count - 1)
    }

    /// The index after `index`, wrapping from the last item to the first.
    public static func next(after index: Int, count: Int) -> Int {
        wrapped(index + 1, count: count)
    }

    /// The index before `index`, wrapping from the first item to the last.
    public static func previous(before index: Int, count: Int) -> Int {
        wrapped(index - 1, count: count)
    }

    /// The shortest signed number of steps from `from` to `to` on a ring of `count` items.
    /// Positive means forward. Ties go forward. Useful to pick a slide direction.
    public static func shortestDistance(from: Int, to: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let forward = wrapped(wrapped(to, count: count) - wrapped(from, count: count), count: count)
        return forward * 2 <= count ? forward : forward - count
    }

    /// The number of pages needed for `itemCount` items, `perPage` at a time.
    public static func pageCount(itemCount: Int, perPage: Int) -> Int {
        guard itemCount > 0, perPage > 0 else { return 0 }
        return (itemCount + perPage - 1) / perPage
    }

    /// The page that holds `index`.
    public static func page(containing index: Int, perPage: Int) -> Int {
        guard perPage > 0, index > 0 else { return 0 }
        return index / perPage
    }

    /// How many whole cards of `itemWidth` fit in `containerWidth` with `spacing` between them. At least 1.
    public static func visibleCount(containerWidth: Double, itemWidth: Double, spacing: Double) -> Int {
        guard containerWidth.isFinite, itemWidth.isFinite, spacing.isFinite, itemWidth > 0 else { return 1 }
        let spacing = max(spacing, 0)
        let count = Int(((containerWidth + spacing) / (itemWidth + spacing)).rounded(.down))
        return max(count, 1)
    }
}

/// Scroll-driven parallax: how far the artwork inside a card slides as the card moves across the screen.
public enum ParallaxMath {
    /// Where a card's center sits in its container: -1 at the leading edge, 0 in the middle, 1 at the trailing edge.
    /// Clamped to -1...1; 0 for an invalid container.
    public static func normalizedPosition(midX: Double, containerWidth: Double) -> Double {
        guard containerWidth.isFinite, containerWidth > 0, midX.isFinite else { return 0 }
        let half = containerWidth / 2
        return min(max((midX - half) / half, -1), 1)
    }

    /// The horizontal artwork offset for a card centered at `midX`, between `-maxOffset` and `maxOffset`.
    /// Cards on the right show more of their artwork's left side, as if the artwork sat further back.
    public static func offset(midX: Double, containerWidth: Double, maxOffset: Double) -> Double {
        guard maxOffset.isFinite, maxOffset > 0 else { return 0 }
        let position = normalizedPosition(midX: midX, containerWidth: containerWidth)
        return position == 0 ? 0 : -position * maxOffset
    }
}
