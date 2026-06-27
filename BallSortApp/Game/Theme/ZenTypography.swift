import SwiftUI

// Typography tokens (E12.3) for the Zen Garden identity.
//
// Canvas type system: Nunito (UI) + Spectral (brand). On-device mapping (per
// docs/design/ZEN_GARDEN.md): **Nunito → SF Rounded** (`.rounded` system design),
// **Spectral → serif** (`.serif` system design). Using the system faces gives full
// Dynamic Type scaling for free — every token is built on a `TextStyle` so it scales
// with the user's preferred size, while the design + weight match the canvas intent.
//
// Spectral as a bundled custom font (the brand wordmark) is a follow-up; until the
// `.ttf` is added, brand text uses the system serif, which is the documented
// stand-in and visually close for the wordmark/display moments.
//
// Canvas reference sizes are noted per token. Weights map Nunito → system:
// ExtraBold → `.heavy`, Bold → `.bold`, SemiBold → `.semibold`.
enum ZenFont {
    /// BRAND — Spectral Light · 32. Wordmark / hero ("Ball Sort").
    static let brand = Font.system(.largeTitle, design: .serif).weight(.light)

    /// DISPLAY — Nunito ExtraBold · 30/36. Big overlay moments ("Solved!").
    static let display = Font.system(.largeTitle, design: .rounded).weight(.heavy)

    /// TITLE — Nunito Bold · 22/28. Screen titles, "Level 7 · Hard".
    static let title = Font.system(.title2, design: .rounded).weight(.bold)

    /// BODY — Nunito SemiBold · 17/24. Instructional / body copy.
    static let body = Font.system(.body, design: .rounded).weight(.semibold)

    /// CAPTION — Nunito Bold · 13 · +0.08em. HUD labels (MOVES/TIME/SORTED).
    /// Apply the tracking with `.zenCaption()`; this is the bare font.
    static let caption = Font.system(.caption, design: .rounded).weight(.bold)

    /// NUMERIC — Nunito ExtraBold · tabular. HUD values (128, 02:14) — never jitters.
    static let numeric = Font.system(.title2, design: .rounded).weight(.heavy).monospacedDigit()

    /// BUTTON — primary/secondary button labels. Nunito Bold.
    static let button = Font.system(.body, design: .rounded).weight(.bold)

    /// STAT VALUE — large tabular numbers in overlay cards (moves/time). Like NUMERIC, larger.
    static let statValue = Font.system(.title, design: .rounded).weight(.heavy).monospacedDigit()

    /// STATUS — small supporting/status text (overlay sublabels). Nunito SemiBold.
    static let status = Font.system(.caption, design: .rounded).weight(.semibold)

    /// HEADLINE — section headlines (settings groups). Nunito Bold.
    static let headline = Font.system(.headline, design: .rounded).weight(.bold)
}

extension Text {
    /// Caption style with the canvas's +0.08em tracking. Use for HUD/section labels.
    func zenCaption() -> some View {
        self.font(ZenFont.caption).tracking(0.9)
    }
}
