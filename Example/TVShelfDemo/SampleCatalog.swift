import Foundation
import TVShelfKit

/// A made-up streaming catalog. Every title, brand and synopsis is fictional, and all artwork is
/// generated from these values by `ShelfPlaceholderArtwork`, so the app needs no network or assets.
enum SampleCatalog {
    static let continueID = "continue-watching"
    static let trendingID = "trending"
    static let topTenID = "top-ten"
    static let newEpisodesID = "new-episodes"
    static let becauseID = "because-you-watched"

    static let featured: [ShelfItem] = [
        ShelfItem(
            id: "northern-lights",
            title: "Northern Lights",
            summary: "A radio operator on a remote Arctic station picks up a signal that should not exist, and a quiet winter turns into a race against the polar night.",
            genres: ["Sci-Fi", "Mystery"],
            year: 2026,
            runtime: 6_840,
            contentRating: "TV-14",
            badge: "New Season",
            symbolName: "sparkles"
        ),
        ShelfItem(
            id: "paper-harbor",
            title: "Paper Harbor",
            summary: "Three siblings inherit a failing shipyard and one last order for a boat nobody alive knows how to build.",
            genres: ["Drama", "Family"],
            year: 2025,
            runtime: 7_020,
            contentRating: "PG",
            badge: "Original",
            symbolName: "sailboat.fill"
        ),
        ShelfItem(
            id: "glass-canyon",
            title: "Glass Canyon",
            summary: "A geologist and a stunt pilot chase a storm across the desert to prove a canyon is singing.",
            genres: ["Adventure"],
            year: 2026,
            runtime: 6_300,
            contentRating: "PG-13",
            symbolName: "mountain.2.fill"
        ),
    ]

    static let continueWatching: [ShelfItem] = [
        ShelfItem(id: "midnight-relay-s2e5", title: "Midnight Relay", subtitle: "S2 · E5", genres: ["Thriller"], runtime: 3_120, symbolName: "bolt.fill", progress: 0.42),
        ShelfItem(id: "quiet-orbit", title: "The Quiet Orbit", genres: ["Sci-Fi"], year: 2024, runtime: 7_560, symbolName: "moon.stars.fill", progress: 0.71),
        ShelfItem(id: "saltwater-kings-s1e3", title: "Saltwater Kings", subtitle: "S1 · E3", genres: ["Documentary"], runtime: 2_880, symbolName: "fish.fill", progress: 0.18),
        ShelfItem(id: "copper-fields", title: "Copper Fields", genres: ["Western"], year: 2023, runtime: 6_600, symbolName: "sun.max.fill", progress: 0.88),
        ShelfItem(id: "velvet-circuit-s3e1", title: "Velvet Circuit", subtitle: "S3 · E1", genres: ["Comedy"], runtime: 1_680, symbolName: "music.note", progress: 0.3),
    ]

    static let trending: [ShelfItem] = [
        ShelfItem(id: "echoes-of-io", title: "Echoes of Io", genres: ["Sci-Fi"], year: 2026, symbolName: "globe.americas.fill"),
        ShelfItem(id: "hollow-pines", title: "Hollow Pines", genres: ["Horror"], year: 2025, badge: "New", symbolName: "leaf.fill"),
        ShelfItem(id: "emberfall", title: "Emberfall", genres: ["Fantasy"], year: 2026, symbolName: "flame.fill"),
        ShelfItem(id: "atlas-street", title: "Atlas Street", genres: ["Crime"], year: 2024, symbolName: "building.2.fill"),
        ShelfItem(id: "kestrel", title: "Kestrel", genres: ["Action"], year: 2026, symbolName: "bird.fill"),
        ShelfItem(id: "blue-hour", title: "Blue Hour", genres: ["Romance"], year: 2025, symbolName: "cloud.moon.fill"),
        ShelfItem(id: "signal-noise", title: "Signal & Noise", genres: ["Documentary"], year: 2026, symbolName: "antenna.radiowaves.left.and.right"),
        ShelfItem(id: "tidewater", title: "Tidewater", genres: ["Drama"], year: 2023, symbolName: "water.waves"),
    ]

    static let topTen: [ShelfItem] = [
        ShelfItem(id: "neon-tides", title: "Neon Tides", genres: ["Thriller"], symbolName: "waveform"),
        ShelfItem(id: "last-lighthouse", title: "The Last Lighthouse", genres: ["Drama"], symbolName: "light.beacon.max.fill"),
        ShelfItem(id: "orbit-kitchen", title: "Orbit Kitchen", genres: ["Reality"], symbolName: "fork.knife"),
        ShelfItem(id: "paper-harbor", title: "Paper Harbor", genres: ["Drama"], symbolName: "sailboat.fill"),
        ShelfItem(id: "wild-circuit", title: "Wild Circuit", genres: ["Sports"], symbolName: "flag.checkered"),
        ShelfItem(id: "snowline", title: "Snowline", genres: ["Adventure"], symbolName: "snowflake"),
    ]

    static let newEpisodes: [ShelfItem] = [
        ShelfItem(id: "midnight-relay-s2e6", title: "Midnight Relay", subtitle: "S2 · E6 · Friday", symbolName: "bolt.fill"),
        ShelfItem(id: "velvet-circuit-s3e2", title: "Velvet Circuit", subtitle: "S3 · E2", badge: "New", symbolName: "music.note"),
        ShelfItem(id: "saltwater-kings-s1e4", title: "Saltwater Kings", subtitle: "S1 · E4", symbolName: "fish.fill"),
        ShelfItem(id: "hare-and-hound", title: "Hare & Hound", subtitle: "S1 · E1", badge: "Premiere", symbolName: "hare.fill"),
        ShelfItem(id: "tram-stories", title: "Tram Stories", subtitle: "S4 · E9", symbolName: "tram.fill"),
    ]

    static let because: [ShelfItem] = [
        ShelfItem(id: "polar-drift", title: "Polar Drift", genres: ["Sci-Fi"], symbolName: "snowflake"),
        ShelfItem(id: "atom-heart", title: "Atom Heart", genres: ["Sci-Fi"], symbolName: "atom"),
        ShelfItem(id: "binocular-summer", title: "Binocular Summer", genres: ["Drama"], symbolName: "binoculars.fill"),
        ShelfItem(id: "night-shift", title: "Night Shift", genres: ["Mystery"], symbolName: "moon.fill"),
        ShelfItem(id: "storm-chasers", title: "Storm Chasers", genres: ["Documentary"], symbolName: "cloud.bolt.rain.fill"),
        ShelfItem(id: "unit-nine", title: "Unit Nine", genres: ["Family"], symbolName: "pawprint.fill"),
    ]

    static let shelves: [Shelf] = [
        Shelf.continueWatching(id: continueID, from: continueWatching),
        Shelf(id: trendingID, title: "Trending Now", layout: .poster, items: trending),
        Shelf(id: topTenID, title: "Top 10 Today", subtitle: "The most watched titles in your region", layout: .ranked, items: topTen),
        Shelf(id: newEpisodesID, title: "New Episodes", layout: .landscape, items: newEpisodes),
        Shelf(id: becauseID, title: "Because You Watched Northern Lights", layout: .poster, items: because),
    ]

    /// The in-progress episode shown by the detail screenshot.
    static let detailItem = ShelfItem(
        id: "midnight-relay-s2e5",
        title: "Midnight Relay",
        subtitle: "Season 2 · Episode 5 · \"Dead Air\"",
        summary: "With the city's last night courier missing, Mara takes his route alone and finds every drop point was a message meant for her.",
        genres: ["Thriller", "Drama"],
        year: 2026,
        runtime: 3_120,
        contentRating: "TV-MA",
        badge: "Continue",
        symbolName: "bolt.fill",
        progress: 0.42
    )
}
