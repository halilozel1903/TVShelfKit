import Foundation

/// Deterministic colors and composition for generated placeholder artwork.
///
/// The values come from a stable FNV-1a hash of a seed string (usually the item's `id`), not from
/// `hashValue`, which changes between launches. The same seed always gives the same artwork.
public struct ArtworkPalette: Hashable, Sendable {
    /// Main hue, 0..<1.
    public var hue: Double
    /// Hue of the gradient's dark end, 0..<1.
    public var secondaryHue: Double
    /// Center of the glow, in unit coordinates.
    public var glowX: Double
    public var glowY: Double
    /// Rotation of the symbol in degrees, -18...18.
    public var tilt: Double

    public init(seed: String) {
        let hash = Self.fnv1a(seed)
        hue = Double(hash % 360) / 360
        let shift = 0.06 + Double((hash >> 12) % 100) / 100 * 0.16
        secondaryHue = (hue + shift).truncatingRemainder(dividingBy: 1)
        glowX = 0.2 + Double((hash >> 24) % 60) / 100
        glowY = 0.15 + Double((hash >> 32) % 40) / 100
        tilt = Double(Int((hash >> 40) % 37) - 18)
    }

    /// 64-bit FNV-1a over the UTF-8 bytes of `string`.
    public static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}
