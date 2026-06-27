import Foundation
import BallSortCore

/// App-layer accessibility mappings for `BallColor` (E9.4).
///
/// Like the SwiftUI `Color` palette, these stay in the App layer so `BallSortCore`
/// remains UI- and presentation-free (ADR-0001). They back two needs:
/// - **VoiceOver**: a spoken color name and a per-ball label.
/// - **Color-blind safety**: a distinct SF Symbol badge per color, so the six
///   balls are distinguishable by shape and not hue alone.
///
/// The color name and ball label are built as `String`s for VoiceOver overloads
/// that don't take a `LocalizedStringKey`, so they go through `String(localized:)`
/// with stable keys to stay translatable via `Localizable.xcstrings` (E9.5). The
/// English output is unchanged from before localization.
extension BallColor {
    /// The human-readable color name spoken by VoiceOver, e.g. `"yellow"`.
    var accessibilityColorName: String {
        switch self {
        case .yellow: String(localized: "color.yellow", defaultValue: "yellow")
        case .orange: String(localized: "color.orange", defaultValue: "orange")
        case .pink:   String(localized: "color.pink", defaultValue: "pink")
        case .green:  String(localized: "color.green", defaultValue: "green")
        case .blue:   String(localized: "color.blue", defaultValue: "blue")
        case .purple: String(localized: "color.purple", defaultValue: "purple")
        }
    }

    /// The full VoiceOver label for a single ball, e.g. `"yellow ball"`.
    var ballAccessibilityLabel: String {
        String(localized: "ball.label", defaultValue: "\(accessibilityColorName) ball")
    }

    /// A distinct SF Symbol drawn as a color-blind-safe badge on the ball.
    ///
    /// Six clearly different filled shapes so each color reads as a unique glyph
    /// regardless of hue perception.
    var accessibilitySymbolName: String {
        switch self {
        case .yellow: "circle.fill"
        case .orange: "triangle.fill"
        case .pink:   "square.fill"
        case .green:  "diamond.fill"
        case .blue:   "star.fill"
        case .purple: "hexagon.fill"
        }
    }
}
