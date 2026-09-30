import SwiftUI

/// One focusable card: artwork with focus scale, shadow and parallax, an optional badge, a progress
/// bar for Continue Watching, a rank number for Top 10 rows and the title underneath.
public struct ShelfCard<Artwork: View>: View {
    public var item: ShelfItem
    public var layout: ShelfLayout
    public var rank: Int?
    public var showsTitle: Bool
    private let action: () -> Void
    private let artwork: Artwork

    var focusBinding: FocusState<ShelfFocusID?>.Binding?
    var focusID: ShelfFocusID?

    @Environment(\.shelfMetrics) private var metrics

    /// - Parameters:
    ///   - item: The item to show.
    ///   - layout: The card shape. `.continueWatching` adds a progress bar, `.ranked` draws `rank` beside the card.
    ///   - rank: The number drawn beside `.ranked` cards, usually the position in the row starting at 1.
    ///   - showsTitle: Draws the title (and the time left for Continue Watching) under the card.
    ///   - action: Called when the card is selected.
    ///   - artwork: The card's image. It is sized and clipped for you.
    public init(
        item: ShelfItem,
        layout: ShelfLayout = .poster,
        rank: Int? = nil,
        showsTitle: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder artwork: () -> Artwork
    ) {
        self.item = item
        self.layout = layout
        self.rank = rank
        self.showsTitle = showsTitle
        self.action = action
        self.artwork = artwork()
    }

    public var body: some View {
        let size = metrics.cardSize(for: layout)
        if layout == .ranked, let rank {
            HStack(alignment: .bottom, spacing: -size.width * 0.16) {
                Text(String(rank))
                    .font(.system(size: size.height * 0.62, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineLimit(1)
                    .fixedSize()
                    .offset(y: size.height * 0.1)
                    .accessibilityHidden(true)
                card(size: size)
            }
        } else {
            card(size: size)
        }
    }

    private func card(size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: size.height * (metrics.focusedScale - 1) / 2 + 12) {
            Button(action: action) {
                ShelfParallax(amount: metrics.parallaxAmount, referenceWidth: metrics.parallaxReferenceWidth) {
                    artwork
                }
                .frame(width: size.width, height: size.height)
                .overlay(alignment: .topLeading) {
                    if let badge = item.badge, !badge.isEmpty {
                        Text(badge.uppercased())
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, metrics.cornerRadius * 0.6)
                            .padding(.vertical, metrics.cornerRadius * 0.25)
                            .background(Capsule().fill(Color(red: 0.9, green: 0.12, blue: 0.16)))
                            .padding(metrics.cornerRadius * 0.7)
                    }
                }
                .overlay(alignment: .bottom) {
                    if layout == .continueWatching, let progress = item.progress {
                        ShelfProgressBar(progress: progress)
                            .padding(.horizontal, metrics.cornerRadius)
                            .padding(.top, metrics.cornerRadius * 2)
                            .padding(.bottom, metrics.cornerRadius * 0.8)
                            .background(
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.75)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(ShelfCardButtonStyle(cornerRadius: metrics.cornerRadius, focusedScale: metrics.focusedScale))
            .modifier(OptionalFocusModifier(binding: focusBinding, id: focusID))
            .accessibilityLabel(Text(accessibilityText))

            if showsTitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    if layout == .continueWatching, let remaining = item.remainingText {
                        Text(remaining)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(width: size.width, alignment: .leading)
                .accessibilityHidden(true)
            }
        }
    }

    private var accessibilityText: String {
        var parts = [item.title]
        if let rank, layout == .ranked { parts.insert("Number \(rank)", at: 0) }
        if let subtitle = item.subtitle { parts.append(subtitle) }
        if layout == .continueWatching, let remaining = item.remainingText { parts.append(remaining) }
        return parts.joined(separator: ", ")
    }

    func focus(_ binding: FocusState<ShelfFocusID?>.Binding, id: ShelfFocusID) -> Self {
        var copy = self
        copy.focusBinding = binding
        copy.focusID = id
        return copy
    }
}

extension ShelfCard where Artwork == ShelfPlaceholderArtwork {
    /// A card with generated placeholder artwork.
    public init(
        item: ShelfItem,
        layout: ShelfLayout = .poster,
        rank: Int? = nil,
        showsTitle: Bool = true,
        action: @escaping () -> Void
    ) {
        self.init(item: item, layout: layout, rank: rank, showsTitle: showsTitle, action: action) {
            ShelfPlaceholderArtwork(item: item, slot: .card(layout))
        }
    }
}
