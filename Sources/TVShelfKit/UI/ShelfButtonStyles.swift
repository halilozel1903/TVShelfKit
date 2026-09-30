import SwiftUI

/// The focus effect of shelf cards: the focused card grows, lifts on a soft shadow and gets a thin
/// highlight; pressing it pushes it back a little.
///
/// On tvOS a custom button style replaces the system focus effect, so this style draws its own.
public struct ShelfCardButtonStyle: ButtonStyle {
    public var cornerRadius: CGFloat
    public var focusedScale: CGFloat

    public init(cornerRadius: CGFloat = 16, focusedScale: CGFloat = 1.1) {
        self.cornerRadius = cornerRadius
        self.focusedScale = focusedScale
    }

    public func makeBody(configuration: Configuration) -> some View {
        ShelfCardButtonBody(configuration: configuration, cornerRadius: cornerRadius, focusedScale: focusedScale)
    }
}

private struct ShelfCardButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let cornerRadius: CGFloat
    let focusedScale: CGFloat

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        configuration.label
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(Color.white.opacity(isFocused ? 0.85 : 0), lineWidth: 3)
            }
            .scaleEffect(scale)
            .shadow(
                color: Color.black.opacity(isFocused ? 0.6 : 0.25),
                radius: isFocused ? 26 : 8,
                x: 0,
                y: isFocused ? 22 : 6
            )
            .zIndex(isFocused ? 1 : 0)
            .animation(reduceMotion ? nil : Animation.spring(response: 0.32, dampingFraction: 0.72), value: isFocused)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var scale: CGFloat {
        let base = isFocused ? focusedScale : 1
        return configuration.isPressed ? base * 0.96 : base
    }
}

/// Capsule buttons for the hero banner and detail screens: translucent at rest, white when focused.
public struct HeroButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        HeroButtonBody(configuration: configuration)
    }
}

private struct HeroButtonBody: View {
    let configuration: ButtonStyleConfiguration

    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.shelfMetrics) private var metrics

    var body: some View {
        configuration.label
            .font(.headline)
            .lineLimit(1)
            .padding(.horizontal, metrics.cornerRadius * 2.2)
            .padding(.vertical, metrics.cornerRadius)
            .foregroundStyle(isFocused ? Color.black : Color.white)
            .background {
                Capsule().fill(isFocused ? Color.white : Color.white.opacity(0.2))
            }
            .scaleEffect(isFocused ? 1.08 : (configuration.isPressed ? 0.96 : 1))
            .shadow(color: Color.black.opacity(isFocused ? 0.45 : 0), radius: 18, x: 0, y: 10)
            .animation(reduceMotion ? nil : Animation.spring(response: 0.3, dampingFraction: 0.8), value: isFocused)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
