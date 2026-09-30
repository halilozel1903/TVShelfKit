import SwiftUI
import TVShelfKit

/// A title's detail screen built from TVShelfKit parts: generated backdrop, hero buttons,
/// progress bar and a "More Like This" row.
struct DetailView: View {
    let item: ShelfItem
    let related: [ShelfItem]
    let onPlay: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ShelfPlaceholderArtwork(item: item, slot: .hero)
            LinearGradient(
                colors: [Color.black.opacity(0.92), Color.black.opacity(0.55), Color.clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.95)],
                startPoint: UnitPoint(x: 0.5, y: 0.35),
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 36) {
                info
                ShelfRow(
                    shelf: Shelf(id: "related", title: "More Like This", layout: .landscape, items: related),
                    showsTitles: false
                ) { _ in }
            }
            .padding(.bottom, 40)
        }
        .foregroundStyle(Color.white)
        .background(Color.black)
        .ignoresSafeArea()
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let badge = item.badge {
                Text(badge.uppercased())
                    .font(.system(size: 24, weight: .heavy))
                    .tracking(4)
                    .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.35))
            }
            Text(item.title)
                .font(.system(size: 84, weight: .heavy))
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.system(size: 32, weight: .semibold))
            }
            Text(item.metadataLine)
                .font(.system(size: 26))
                .foregroundStyle(Color.white.opacity(0.7))
            if let summary = item.summary {
                Text(summary)
                    .font(.system(size: 28))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(3)
                    .frame(maxWidth: 960, alignment: .leading)
            }
            if let progress = item.progress {
                HStack(spacing: 20) {
                    ShelfProgressBar(progress: progress)
                        .frame(width: 360)
                    if let remaining = item.remainingText {
                        Text(remaining)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                }
            }
            HStack(spacing: 28) {
                Button(action: onPlay) {
                    Label(item.isInProgress ? "Resume" : "Play", systemImage: "play.fill")
                }
                Button {} label: {
                    Label("Start Over", systemImage: "arrow.counterclockwise")
                }
                Button {} label: {
                    Label("My List", systemImage: "plus")
                }
            }
            .buttonStyle(HeroButtonStyle())
            .padding(.top, 8)
        }
        .padding(.horizontal, 80)
    }
}
