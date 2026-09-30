import SwiftUI

private struct ShelfMetricsKey: EnvironmentKey {
    static let defaultValue = ShelfMetrics.platformDefault
}

private struct ShelfParallaxInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// Sizes and spacing used by every TVShelfKit view below.
    public var shelfMetrics: ShelfMetrics {
        get { self[ShelfMetricsKey.self] }
        set { self[ShelfMetricsKey.self] = newValue }
    }

    /// How far artwork inside a card can be cut off on either side by the parallax effect.
    /// Keep text in custom artwork at least this far from the leading and trailing edges.
    public var shelfParallaxInset: CGFloat {
        get { self[ShelfParallaxInsetKey.self] }
        set { self[ShelfParallaxInsetKey.self] = newValue }
    }
}

extension View {
    /// Sets the sizes and spacing of shelves, cards and the hero banner in this view.
    public func shelfMetrics(_ metrics: ShelfMetrics) -> some View {
        environment(\.shelfMetrics, metrics)
    }

    /// `focusSection()` where it exists (tvOS and macOS), so moving focus up or down lands on the
    /// nearest card of the next row instead of skipping it.
    func shelfFocusSection() -> some View {
        #if os(tvOS) || os(macOS)
        return focusSection()
        #else
        return self
        #endif
    }
}

/// Where a piece of artwork is shown, so an artwork builder can pick the right image.
public enum ShelfArtworkSlot: Hashable, Sendable {
    /// The full-width hero banner.
    case hero
    /// A card on a shelf with the given layout.
    case card(ShelfLayout)

    /// The card layout, or `.landscape` for the hero.
    public var layout: ShelfLayout {
        switch self {
        case .hero: .landscape
        case .card(let layout): layout
        }
    }
}

/// Applies `.focused(_:equals:)` only when a binding is available.
struct OptionalFocusModifier: ViewModifier {
    let binding: FocusState<ShelfFocusID?>.Binding?
    let id: ShelfFocusID?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let binding, let id {
            content.focused(binding, equals: id)
        } else {
            content
        }
    }
}

/// Applies `.defaultFocus(_:_:priority:)` only when there is something to focus.
/// With `userInitiated`, it also applies when focus moves into the view (focus memory), not just on appear.
struct DefaultShelfFocusModifier: ViewModifier {
    let binding: FocusState<ShelfFocusID?>.Binding?
    let id: ShelfFocusID?
    let userInitiated: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if let binding, let id {
            content.defaultFocus(binding, id, priority: userInitiated ? DefaultFocusEvaluationPriority.userInitiated : DefaultFocusEvaluationPriority.automatic)
        } else {
            content
        }
    }
}
