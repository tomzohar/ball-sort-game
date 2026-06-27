import SwiftUI

// "Zen Garden" design tokens (E12.0). The single App-layer source of truth for the
// reskin's semantic colors, spacing, corner radii, and elevation. Views reference
// these tokens instead of hand-tuning hex/numbers inline, so the whole look is tuned
// from one place — the same discipline `AnimationConstants` applies to motion.
//
// Exact values come from the live Zen Garden canvas token sheet (see
// docs/design/ZEN_TOKENS.md). Light is the hero appearance; every color carries a
// matching dark value. Core stays UI-free (ADR-0001) — tokens live in the App layer.

// MARK: - Dynamic color helper

extension Color {
    /// A color that resolves to `light` in light mode and `dark` in dark mode.
    ///
    /// Backed by a `UIColor` dynamic provider so a single `Color` adapts to the
    /// active appearance without callers branching on `colorScheme`.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    /// Convenience: build a light/dark pair straight from 24-bit RGB hex literals.
    init(lightHex: UInt32, darkHex: UInt32) {
        self.init(light: Color(hex: lightHex), dark: Color(hex: darkHex))
    }
}

// MARK: - Semantic colors

/// Semantic color tokens (light + dark) for the Zen Garden identity.
///
/// Maps the canvas token sheet 1:1. Use these for every surface/text/accent need so
/// light- and dark-mode behaviour is consistent and centralized.
enum ZenColor {
    /// App background — the bright "stage" the garden sits on.
    static let stage = Color(lightHex: 0xF4EDDE, darkHex: 0x1B211A)
    /// Primary surface — the raked-sand bed the tubes rest in.
    static let sandBed = Color(lightHex: 0xE6D9BF, darkHex: 0x2C3128)
    /// Frames and hairline borders around stones/tubes/cards.
    static let stoneFrame = Color(lightHex: 0xC9BBA0, darkHex: 0x3A3F33)
    /// Raised surface — cards, overlays, pills.
    static let elevated = Color(lightHex: 0xFBF7EF, darkHex: 0x242A22)
    /// Primary text.
    static let textPrimary = Color(lightHex: 0x3B362C, darkHex: 0xECE6D6)
    /// Secondary / muted text.
    static let textSecondary = Color(lightHex: 0x8A8170, darkHex: 0x9C9686)
    /// Accent — calm "water" teal. Primary actions, selection, hint glow.
    static let accent = Color(lightHex: 0x4F9D8B, darkHex: 0x6FB9A6)
    /// Success — "moss" green. Completed tubes, win.
    static let success = Color(lightHex: 0x6E9E62, darkHex: 0x7FB073)
}

// MARK: - Spacing scale

/// Spacing scale (canvas: 4 · 8 · 12 · 16 · 24 · 32). Named by t-shirt size.
enum ZenSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner radius scale

/// Corner-radius scale (canvas: 10 · 16 · 22 · 28 · full).
enum ZenRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let xl: CGFloat = 28
    /// "Full" — capsule/pill rounding. Large enough to fully round common control
    /// heights; clamp against the shape's own bounds with `.continuous` capsules.
    static let full: CGFloat = 999
}

// MARK: - Elevation scale

/// A soft drop-shadow recipe. The Zen elevation scale: `rest` · `card` · `modal`.
struct ZenShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    /// Almost flat — a whisper of depth for stones/pills at rest.
    static let rest = ZenShadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 2)
    /// Lifted card — overlays, the win card, raised pills.
    static let card = ZenShadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 8)
    /// Modal — sheets and the topmost overlay card.
    static let modal = ZenShadow(color: .black.opacity(0.22), radius: 28, x: 0, y: 14)
}

extension View {
    /// Apply a named Zen elevation.
    func zenShadow(_ shadow: ZenShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}
