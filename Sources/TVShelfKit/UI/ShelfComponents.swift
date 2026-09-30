import SwiftUI

/// A thin watch-progress bar.
public struct ShelfProgressBar: View {
    public var progress: Double
    public var tint: Color

    public init(progress: Double, tint: Color = Color(red: 0.9, green: 0.12, blue: 0.16)) {
        self.progress = progress
        self.tint = tint
    }

    public var body: some View {
        let value = PlaybackProgress.clamp(progress) ?? 0
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.3))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * value)
            }
        }
        .frame(height: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progress"))
        .accessibilityValue(Text(PlaybackProgress.percentText(value)))
    }
}

/// The title (and optional subtitle) above a shelf.
public struct ShelfSectionHeader: View {
    public var title: String
    public var subtitle: String?

    public init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Slides its content sideways as it moves across the screen, so artwork seems to sit behind the card.
/// The content is laid out `amount` points wider on each side and clipped by the card.
struct ShelfParallax<Content: View>: View {
    let amount: CGFloat
    let referenceWidth: CGFloat
    let content: Content

    init(amount: CGFloat, referenceWidth: CGFloat, @ViewBuilder content: () -> Content) {
        self.amount = amount
        self.referenceWidth = referenceWidth
        self.content = content()
    }

    var body: some View {
        if amount > 0 {
            GeometryReader { proxy in
                let midX = proxy.frame(in: .global).midX
                let offset = ParallaxMath.offset(
                    midX: Double(midX),
                    containerWidth: Double(referenceWidth),
                    maxOffset: Double(amount)
                )
                content
                    .environment(\.shelfParallaxInset, amount * 2)
                    .frame(width: proxy.size.width + amount * 2, height: proxy.size.height)
                    .offset(x: CGFloat(offset) - amount)
            }
        } else {
            content
        }
    }
}

/// Generated artwork: a gradient, a soft glow, a large SF Symbol and the title, all derived from the
/// item's `id`, so the same item always looks the same. Use it for placeholders, previews and demos.
public struct ShelfPlaceholderArtwork: View {
    public var item: ShelfItem
    public var slot: ShelfArtworkSlot

    public init(item: ShelfItem, slot: ShelfArtworkSlot = .card(.poster)) {
        self.item = item
        self.slot = slot
    }

    @Environment(\.shelfParallaxInset) private var parallaxInset

    public var body: some View {
        let palette = ArtworkPalette(seed: item.id)
        let isHero = slot == .hero
        let isPortrait = slot.layout.isPortrait
        GeometryReader { proxy in
            let size = proxy.size
            let side = min(size.width, size.height)
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        Color(hue: palette.hue, saturation: 0.72, brightness: 0.62),
                        Color(hue: palette.secondaryHue, saturation: 0.85, brightness: 0.2),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color(hue: palette.hue, saturation: 0.4, brightness: 1).opacity(0.5))
                    .frame(width: side * 1.1, height: side * 1.1)
                    .blur(radius: side * 0.22)
                    .position(x: size.width * palette.glowX, y: size.height * palette.glowY)
                Image(systemName: item.symbolName ?? "film")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(Color.white.opacity(isHero ? 0.3 : 0.4))
                    .frame(width: side * (isHero ? 0.62 : 0.52), height: side * (isHero ? 0.62 : 0.52))
                    .rotationEffect(.degrees(palette.tilt))
                    .position(
                        x: size.width * (isPortrait ? 0.5 : 0.7),
                        y: size.height * (isPortrait ? 0.36 : 0.45)
                    )
                if !isHero {
                    Text(item.title.uppercased())
                        .font(.system(size: max(10, side * (isPortrait ? 0.14 : 0.13)), weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                        .lineLimit(isPortrait ? 3 : 2)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
                        .frame(width: max(0, size.width - side * 0.18 - parallaxInset * 2), alignment: .leading)
                        .padding(.vertical, side * 0.09)
                        .padding(.horizontal, side * 0.09 + parallaxInset)
                        .frame(width: size.width, height: size.height, alignment: .bottomLeading)
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .accessibilityHidden(true)
    }
}
