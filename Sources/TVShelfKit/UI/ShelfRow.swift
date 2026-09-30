import SwiftUI

/// A section header and a horizontal, focus-driven row of cards.
///
/// Focused cards are never clipped by the row, moving focus up or down lands on the nearest card
/// (a focus section on tvOS), and inside a ``ShelfBrowser`` focus returns to the card you left.
public struct ShelfRow<Artwork: View>: View {
    public var shelf: Shelf
    public var showsTitles: Bool
    private let onSelect: (ShelfItem) -> Void
    private let artwork: (ShelfItem, ShelfLayout) -> Artwork

    var focusBinding: FocusState<ShelfFocusID?>.Binding?
    var rememberedItemID: String?

    @Environment(\.shelfMetrics) private var metrics

    public init(
        shelf: Shelf,
        showsTitles: Bool = true,
        onSelect: @escaping (ShelfItem) -> Void,
        @ViewBuilder artwork: @escaping (ShelfItem, ShelfLayout) -> Artwork
    ) {
        self.shelf = shelf
        self.showsTitles = showsTitles
        self.onSelect = onSelect
        self.artwork = artwork
    }

    public var body: some View {
        let room = metrics.focusRoom(for: shelf.layout)
        VStack(alignment: .leading, spacing: 0) {
            ShelfSectionHeader(shelf.title, subtitle: shelf.subtitle)
                .padding(.horizontal, metrics.horizontalInset)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: metrics.itemSpacing) {
                    ForEach(Array(shelf.items.enumerated()), id: \.element.id) { index, item in
                        cardView(item: item, index: index)
                    }
                }
                .padding(.horizontal, metrics.horizontalInset)
                .padding(.vertical, room)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .padding(.top, -room * 0.5)
            .shelfFocusSection()
            .modifier(DefaultShelfFocusModifier(binding: focusBinding, id: rememberedFocusID, userInitiated: true))
        }
    }

    @ViewBuilder
    private func cardView(item: ShelfItem, index: Int) -> some View {
        let card = ShelfCard(
            item: item,
            layout: shelf.layout,
            rank: shelf.layout == .ranked ? index + 1 : nil,
            showsTitle: showsTitles,
            action: { onSelect(item) },
            artwork: { artwork(item, shelf.layout) }
        )
        if let focusBinding {
            card.focus(focusBinding, id: ShelfFocusID(shelfID: shelf.id, itemID: item.id))
        } else {
            card
        }
    }

    private var rememberedFocusID: ShelfFocusID? {
        guard let rememberedItemID, shelf.items.contains(where: { $0.id == rememberedItemID }) else { return nil }
        return ShelfFocusID(shelfID: shelf.id, itemID: rememberedItemID)
    }

    func focus(_ binding: FocusState<ShelfFocusID?>.Binding, remembering itemID: String?) -> Self {
        var copy = self
        copy.focusBinding = binding
        copy.rememberedItemID = itemID
        return copy
    }
}

extension ShelfRow where Artwork == ShelfPlaceholderArtwork {
    /// A row with generated placeholder artwork.
    public init(shelf: Shelf, showsTitles: Bool = true, onSelect: @escaping (ShelfItem) -> Void) {
        self.init(shelf: shelf, showsTitles: showsTitles, onSelect: onSelect) { item, layout in
            ShelfPlaceholderArtwork(item: item, slot: .card(layout))
        }
    }
}
