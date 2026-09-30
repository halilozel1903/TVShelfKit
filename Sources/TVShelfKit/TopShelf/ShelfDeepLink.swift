import Foundation

/// A URL that opens your app on an item, as used by Top Shelf actions: `myapp://play?id=42`.
public struct ShelfDeepLink: Hashable, Sendable {
    public enum Action: String, Hashable, Sendable, CaseIterable {
        /// Show the item's detail screen.
        case display
        /// Start playback right away.
        case play
    }

    public var action: Action
    public var itemID: String

    public init(action: Action, itemID: String) {
        self.action = action
        self.itemID = itemID
    }

    /// The URL for this link, or `nil` when `scheme` is not a valid URL scheme or the item ID is empty.
    public func url(scheme: String) -> URL? {
        guard Self.isValidScheme(scheme), !itemID.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = action.rawValue
        components.percentEncodedQuery = "id=" + Self.percentEncode(itemID)
        return components.url
    }

    /// Parses a link made by ``url(scheme:)``. Pass `scheme` to accept only your own scheme.
    public init?(url: URL, scheme: String? = nil) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        if let scheme, components.scheme?.lowercased() != scheme.lowercased() { return nil }
        guard
            let host = components.host?.lowercased(),
            let action = Action(rawValue: host),
            let itemID = components.queryItems?.first(where: { $0.name == "id" })?.value,
            !itemID.isEmpty
        else { return nil }
        self.init(action: action, itemID: itemID)
    }

    /// RFC 3986: a letter followed by letters, digits, "+", "-" or ".".
    public static func isValidScheme(_ scheme: String) -> Bool {
        guard let first = scheme.unicodeScalars.first, isASCIILetter(first) else { return false }
        return scheme.unicodeScalars.allSatisfy(isSchemeCharacter)
    }

    private static func isASCIILetter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar {
        case "a"..."z", "A"..."Z": true
        default: false
        }
    }

    private static func isSchemeCharacter(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar {
        case "a"..."z", "A"..."Z", "0"..."9", "+", "-", ".": true
        default: false
        }
    }

    /// Encodes everything except unreserved ASCII characters, so "&", "=", "+" and spaces survive a round trip.
    private static func percentEncode(_ value: String) -> String {
        let unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? value
    }
}
