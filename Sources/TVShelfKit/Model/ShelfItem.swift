import Foundation

/// One title on a shelf: a movie, a show, an episode or anything else you can play.
///
/// `ShelfItem` is a plain value with no UI types, so you can build it anywhere, including a
/// Top Shelf extension or a background task, and compare it in tests.
public struct ShelfItem: Identifiable, Hashable, Sendable {
    /// A stable identifier. It is used for focus, deep links and generated artwork.
    public var id: String
    /// The title shown on the card, in the hero banner and in the Top Shelf.
    public var title: String
    /// A secondary line, for example "Season 2 · Episode 5".
    public var subtitle: String?
    /// A short description shown in the hero banner.
    public var summary: String?
    /// Genres, most important first. The first two appear in ``metadataLine``.
    public var genres: [String]
    /// The release year.
    public var year: Int?
    /// The running time in seconds.
    public var runtime: TimeInterval?
    /// A content rating such as "TV-14" or "PG".
    public var contentRating: String?
    /// A short label drawn on the card, for example "New" or "Live".
    public var badge: String?
    /// An SF Symbol used by ``ShelfPlaceholderArtwork``.
    public var symbolName: String?

    private var storedProgress: Double?

    /// How much has been watched, from 0 to 1. Values outside that range are clamped and
    /// non-finite values become `nil`.
    public var progress: Double? {
        get { storedProgress }
        set { storedProgress = PlaybackProgress.clamp(newValue) }
    }

    public init(
        id: String,
        title: String,
        subtitle: String? = nil,
        summary: String? = nil,
        genres: [String] = [],
        year: Int? = nil,
        runtime: TimeInterval? = nil,
        contentRating: String? = nil,
        badge: String? = nil,
        symbolName: String? = nil,
        progress: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.genres = genres
        self.year = year
        self.runtime = runtime
        self.contentRating = contentRating
        self.badge = badge
        self.symbolName = symbolName
        self.storedProgress = PlaybackProgress.clamp(progress)
    }

    /// `true` when the item has been started but not finished.
    public var isInProgress: Bool {
        PlaybackProgress.isInProgress(progress)
    }

    /// "32m left", "Less than a minute left" or "Watched"; `nil` without a runtime or progress.
    public var remainingText: String? {
        guard let progress, let runtime else { return nil }
        return PlaybackProgress.remainingText(runtime: runtime, progress: progress)
    }

    /// The year, running time, rating and up to two genres, joined with a middle dot:
    /// "2025 · 1h 52m · TV-14 · Drama · Mystery".
    public var metadataLine: String {
        var parts: [String] = []
        if let year { parts.append(String(year)) }
        if let runtime, runtime.isFinite, runtime > 0 { parts.append(PlaybackProgress.durationText(runtime)) }
        if let contentRating, !contentRating.isEmpty { parts.append(contentRating) }
        parts.append(contentsOf: genres.filter { !$0.isEmpty }.prefix(2))
        return parts.joined(separator: " · ")
    }
}
