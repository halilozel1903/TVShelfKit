import Foundation
import Testing
@testable import TVShelfKit

@Suite("PlaybackProgress")
struct PlaybackProgressTests {
    @Test func clamp() {
        #expect(PlaybackProgress.clamp(0.4) == 0.4)
        #expect(PlaybackProgress.clamp(-1) == 0)
        #expect(PlaybackProgress.clamp(3) == 1)
        #expect(PlaybackProgress.clamp(.nan) == nil)
        #expect(PlaybackProgress.clamp(.infinity) == nil)
        #expect(PlaybackProgress.clamp(nil) == nil)
    }

    @Test func inProgressAndFinished() {
        #expect(PlaybackProgress.isInProgress(0.5))
        #expect(!PlaybackProgress.isInProgress(0))
        #expect(!PlaybackProgress.isInProgress(nil))
        #expect(!PlaybackProgress.isInProgress(0.95))
        #expect(PlaybackProgress.isFinished(0.97))
        #expect(!PlaybackProgress.isFinished(0.5))
        #expect(!PlaybackProgress.isFinished(nil))
    }

    @Test(arguments: [
        (0.0, "0m"), (20.0, "0m"), (45.0, "1m"), (2_700.0, "45m"), (3_600.0, "1h"),
        (6_720.0, "1h 52m"), (7_199.0, "2h"), (-5.0, "0m"), (Double.nan, "0m"),
    ])
    func durationText(seconds: Double, expected: String) {
        #expect(PlaybackProgress.durationText(seconds) == expected)
    }

    @Test func remainingText() {
        #expect(PlaybackProgress.remainingText(runtime: 3_600, progress: 0.5) == "30m left")
        #expect(PlaybackProgress.remainingText(runtime: 7_200, progress: 0.4) == "1h 12m left")
        #expect(PlaybackProgress.remainingText(runtime: 3_000, progress: 0.99) == "Watched")
        #expect(PlaybackProgress.remainingText(runtime: 1_000, progress: 0.945) == "Less than a minute left")
        #expect(PlaybackProgress.remainingText(runtime: 600, progress: -3) == "10m left")
        #expect(PlaybackProgress.remainingText(runtime: 0, progress: 0.5) == nil)
        #expect(PlaybackProgress.remainingText(runtime: .nan, progress: 0.5) == nil)
    }

    @Test func percentText() {
        #expect(PlaybackProgress.percentText(0.456) == "46%")
        #expect(PlaybackProgress.percentText(0) == "0%")
        #expect(PlaybackProgress.percentText(2) == "100%")
        #expect(PlaybackProgress.percentText(.nan) == "0%")
    }
}
