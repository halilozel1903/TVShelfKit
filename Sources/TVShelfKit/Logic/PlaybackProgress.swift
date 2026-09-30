import Foundation

/// Formatting and rules for watch progress.
///
/// The text is built by hand rather than with a formatter so it is the same on every device and in tests.
public enum PlaybackProgress {
    /// Progress at or above this counts as watched: the end credits are usually the last 5 %.
    public static let finishedThreshold: Double = 0.95

    /// Clamps `value` to 0...1. `nil`, NaN and infinity return `nil`.
    public static func clamp(_ value: Double?) -> Double? {
        guard let value, value.isFinite else { return nil }
        return min(max(value, 0), 1)
    }

    /// `true` when `progress` is above 0 and below ``finishedThreshold``.
    public static func isInProgress(_ progress: Double?) -> Bool {
        guard let progress = clamp(progress) else { return false }
        return progress > 0 && progress < finishedThreshold
    }

    /// `true` when `progress` reaches ``finishedThreshold``.
    public static func isFinished(_ progress: Double?) -> Bool {
        guard let progress = clamp(progress) else { return false }
        return progress >= finishedThreshold
    }

    /// A running time rounded to whole minutes: "1h 52m", "2h", "45m". Invalid or negative values give "0m".
    public static func durationText(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0m" }
        let minutes = Int((seconds / 60).rounded())
        let hours = minutes / 60
        let rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest)m"
        case (_, 0): return "\(hours)h"
        default: return "\(hours)h \(rest)m"
        }
    }

    /// The time left: "1h 12m left", "8m left", "Less than a minute left" or "Watched".
    /// Returns `nil` when `runtime` is not a positive, finite number.
    public static func remainingText(runtime: TimeInterval, progress: Double) -> String? {
        guard runtime.isFinite, runtime > 0 else { return nil }
        let progress = clamp(progress) ?? 0
        if progress >= finishedThreshold { return "Watched" }
        let remaining = runtime * (1 - progress)
        if remaining < 60 { return "Less than a minute left" }
        return "\(durationText(remaining)) left"
    }

    /// Progress as a whole percentage: "45%".
    public static func percentText(_ progress: Double) -> String {
        let value = clamp(progress) ?? 0
        return "\(Int((value * 100).rounded()))%"
    }
}
