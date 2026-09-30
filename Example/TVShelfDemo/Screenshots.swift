import Foundation
import TVShelfKit

/// Scenes used by CI to capture the README screenshots.
/// Launch with `-screenshot <scene>`; normal launches are unaffected.
enum ScreenshotScene: String {
    /// The home screen with the hero banner's Play button focused.
    case home
    /// A poster in "Trending Now" focused: scaled up, lifted, with its neighbors at rest.
    case focused
    /// A card in "Continue Watching" focused, with progress bars and the time left.
    case continueWatching = "continue"
    /// The detail screen of an episode in progress.
    case detail

    static var current: ScreenshotScene? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-screenshot"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return ScreenshotScene(rawValue: arguments[index + 1])
    }

    /// The card focused when the scene appears; `nil` leaves focus on the hero banner.
    var initialFocus: ShelfFocusID? {
        switch self {
        case .home, .detail:
            return nil
        case .focused:
            return ShelfFocusID(shelfID: SampleCatalog.trendingID, itemID: SampleCatalog.trending[2].id)
        case .continueWatching:
            return ShelfFocusID(shelfID: SampleCatalog.continueID, itemID: SampleCatalog.continueWatching[1].id)
        }
    }
}
