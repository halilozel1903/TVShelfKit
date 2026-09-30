import SwiftUI

/// A full-width, auto-advancing banner of featured items with Play and More Info buttons.
///
/// It advances every `interval`, restarts the countdown whenever focus moves between its buttons,
/// stops while `isPaused` is `true` (``ShelfBrowser`` pauses it while you browse shelves further
/// down or look at a detail screen) and never animates with Reduce Motion on.
public struct HeroBanner<Artwork: View>: View {
    public var items: [ShelfItem]
    public var interval: Duration
    public var autoAdvances: Bool
    public var isPaused: Bool
    public var pausesWhileFocused: Bool
    private let onPlay: (ShelfItem) -> Void
    private let onInfo: ((ShelfItem) -> Void)?
    private let onFocusChange: ((Bool) -> Void)?
    private let artwork: (ShelfItem) -> Artwork

    @State private var index: Int
    @FocusState private var focusedButton: HeroButton?
    @Environment(\.shelfMetrics) private var metrics
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum HeroButton: Hashable {
        case play
        case info
    }

    private struct AdvanceKey: Equatable {
        var index: Int
        var paused: Bool
        var focus: HeroButton?
    }

    /// - Parameters:
    ///   - items: The featured items, shown one at a time.
    ///   - initialIndex: The item shown first.
    ///   - interval: How long each item stays before the next one.
    ///   - autoAdvances: `false` keeps the banner on one item (useful for screenshots).
    ///   - isPaused: Stops advancing while `true`.
    ///   - pausesWhileFocused: Also stops while one of the banner's buttons has focus.
    ///   - onPlay: Called by the Play (or Resume) button.
    ///   - onInfo: Called by the More Info button; the button is hidden when this is `nil`.
    ///   - onFocusChange: Called with `true` when a banner button gains focus and `false` when focus leaves the banner.
    ///   - artwork: The full-bleed background for an item.
    public init(
        items: [ShelfItem],
        initialIndex: Int = 0,
        interval: Duration = .seconds(8),
        autoAdvances: Bool = true,
        isPaused: Bool = false,
        pausesWhileFocused: Bool = false,
        onPlay: @escaping (ShelfItem) -> Void,
        onInfo: ((ShelfItem) -> Void)? = nil,
        onFocusChange: ((Bool) -> Void)? = nil,
        @ViewBuilder artwork: @escaping (ShelfItem) -> Artwork
    ) {
        self.items = items
        self.interval = interval
        self.autoAdvances = autoAdvances
        self.isPaused = isPaused
        self.pausesWhileFocused = pausesWhileFocused
        self.onPlay = onPlay
        self.onInfo = onInfo
        self.onFocusChange = onFocusChange
        self.artwork = artwork
        _index = State(initialValue: CarouselMath.clamped(initialIndex, count: items.count))
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black
            if let item = currentItem {
                artwork(item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .id(item.id)
                    .transition(.opacity)
                    .accessibilityHidden(true)
                LinearGradient(
                    colors: [Color.black.opacity(0.85), Color.black.opacity(0.35), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.9)],
                    startPoint: UnitPoint(x: 0.5, y: 0.45),
                    endPoint: .bottom
                )
                details(for: item)
            }
        }
        .frame(height: metrics.heroHeight)
        .frame(maxWidth: .infinity)
        .clipped()
        .task(id: AdvanceKey(index: index, paused: isAdvancePaused, focus: focusedButton)) {
            guard !isAdvancePaused else { return }
            do {
                try await Task.sleep(for: interval)
            } catch {
                return
            }
            withAnimation(reduceMotion ? nil : Animation.easeInOut(duration: 0.8)) {
                index = CarouselMath.next(after: index, count: items.count)
            }
        }
        .onChange(of: focusedButton) { oldValue, newValue in
            if (oldValue == nil) != (newValue == nil) {
                onFocusChange?(newValue != nil)
            }
        }
        .onChange(of: items.count) { _, count in
            index = CarouselMath.clamped(index, count: count)
        }
    }

    private var currentItem: ShelfItem? {
        items.isEmpty ? nil : items[CarouselMath.clamped(index, count: items.count)]
    }

    private var isAdvancePaused: Bool {
        !autoAdvances || isPaused || items.count < 2 || (pausesWhileFocused && focusedButton != nil)
    }

    private func details(for item: ShelfItem) -> some View {
        VStack(alignment: .leading, spacing: metrics.cornerRadius) {
            if let badge = item.badge, !badge.isEmpty {
                Text(badge.uppercased())
                    .font(.caption)
                    .fontWeight(.heavy)
                    .tracking(3)
                    .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.35))
            }
            Text(item.title)
                .font(.system(size: metrics.heroHeight * 0.11, weight: .heavy))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            let metadata = item.metadataLine
            if !metadata.isEmpty {
                Text(metadata)
                    .font(.callout)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
            if let summary = item.summary, !summary.isEmpty {
                Text(summary)
                    .font(.body)
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(3)
                    .frame(maxWidth: metrics.heroHeight * 1.4, alignment: .leading)
            }
            HStack(spacing: metrics.itemSpacing * 0.6) {
                Button {
                    onPlay(item)
                } label: {
                    Label(item.isInProgress ? "Resume" : "Play", systemImage: "play.fill")
                }
                .focused($focusedButton, equals: .play)

                if let onInfo {
                    Button {
                        onInfo(item)
                    } label: {
                        Label("More Info", systemImage: "info.circle")
                    }
                    .focused($focusedButton, equals: .info)
                }
            }
            .buttonStyle(HeroButtonStyle())
            .padding(.top, metrics.cornerRadius * 0.5)

            if items.count > 1 {
                HeroPageIndicator(count: items.count, current: CarouselMath.clamped(index, count: items.count))
                    .padding(.top, metrics.cornerRadius * 0.5)
            }
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, metrics.horizontalInset)
        .padding(.bottom, metrics.rowSpacing)
    }
}

extension HeroBanner where Artwork == ShelfPlaceholderArtwork {
    /// A hero banner with generated placeholder artwork.
    public init(
        items: [ShelfItem],
        initialIndex: Int = 0,
        interval: Duration = .seconds(8),
        autoAdvances: Bool = true,
        isPaused: Bool = false,
        pausesWhileFocused: Bool = false,
        onPlay: @escaping (ShelfItem) -> Void,
        onInfo: ((ShelfItem) -> Void)? = nil,
        onFocusChange: ((Bool) -> Void)? = nil
    ) {
        self.init(
            items: items,
            initialIndex: initialIndex,
            interval: interval,
            autoAdvances: autoAdvances,
            isPaused: isPaused,
            pausesWhileFocused: pausesWhileFocused,
            onPlay: onPlay,
            onInfo: onInfo,
            onFocusChange: onFocusChange,
            artwork: { item in ShelfPlaceholderArtwork(item: item, slot: .hero) }
        )
    }
}

/// Page dots under the hero banner; the current page is a wider pill.
struct HeroPageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { page in
                Capsule()
                    .fill(page == current ? Color.white : Color.white.opacity(0.35))
                    .frame(width: page == current ? 30 : 10, height: 10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Page \(current + 1) of \(count)"))
    }
}
