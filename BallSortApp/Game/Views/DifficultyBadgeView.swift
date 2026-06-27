import SwiftUI
import BallSortCore

/// A small pill showing the current level number and its difficulty band, e.g.
/// "Level 3 · Hard". A dumb view (ADR-0001) driven by plain values; the only Core
/// type it knows is `Difficulty.Band`.
///
/// Restyled for the "Zen Garden" identity (E12.7): an elevated sand-tone pill that
/// reads calmly on the bright stage. The level number sits in `ZenColor.textPrimary`;
/// the band is colour-coded along a five-step ramp drawn *within* the Zen palette —
/// cool moss/water for easy levels warming to persimmon/plum for the hard end — never
/// the old hot green→red alarm. The token sheet leaves the per-band hues to this unit
/// (docs/design/ZEN_TOKENS.md), so the ramp is derived here.
struct DifficultyBadgeView: View {
    /// The 1-based level number shown to the player.
    let level: Int
    /// The difficulty band of the current level.
    let band: Difficulty.Band

    var body: some View {
        HStack(spacing: ZenSpacing.sm) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                // A soft glow so the dot reads as a calm status light, not an alarm.
                .shadow(color: accent.opacity(0.6), radius: 3)

            Text("Level \(level)")
                .font(ZenFont.title)
                .foregroundStyle(ZenColor.textPrimary)
                // Keep "Level N" on a single line — the designer flagged it wrapping
                // to two lines on the narrow pill. `fixedSize` lets the label claim its
                // natural width; `lineLimit(1)` is a belt-and-braces guard.
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Text("·")
                .font(ZenFont.title)
                .foregroundStyle(ZenColor.textSecondary)

            Text(label)
                .zenCaption()
                .foregroundStyle(accent)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, ZenSpacing.lg)
        .padding(.vertical, ZenSpacing.sm)
        .background(ZenColor.elevated, in: Capsule())
        .overlay(
            Capsule().strokeBorder(accent.opacity(0.45), lineWidth: 1)
        )
        // Lift the pill softly off the sand bed, matching the board's depth cues.
        .zenShadow(.rest)
        .accessibilityElement(children: .ignore)
        // Composed VoiceOver label: built as a String for the non-localized
        // `accessibilityLabel(_:)` overload, so route it through `String(localized:)`
        // with a stable key (E9.5). `bandName` is the localized band word.
        .accessibilityLabel(
            String(
                localized: "difficulty.accessibility",
                defaultValue: "Level \(level), \(bandName) difficulty"
            )
        )
    }

    /// Human-facing label for each band, as a `LocalizedStringKey` so the visible
    /// `Text(label)` auto-localizes against `Localizable.xcstrings` (E9.5).
    private var label: LocalizedStringKey {
        switch band {
        case .trivial: "Trivial"
        case .easy:    "Easy"
        case .medium:  "Medium"
        case .hard:    "Hard"
        case .expert:  "Expert"
        }
    }

    /// The localized band word as a plain `String`, for composing the VoiceOver label.
    private var bandName: String {
        switch band {
        case .trivial: String(localized: "Trivial")
        case .easy:    String(localized: "Easy")
        case .medium:  String(localized: "Medium")
        case .hard:    String(localized: "Hard")
        case .expert:  String(localized: "Expert")
        }
    }

    /// Band accent colour: a calm five-step ramp drawn entirely from the Zen palette,
    /// cool (low difficulty) → warm (high). Moss and water are the semantic tokens;
    /// the warm end reuses the stone hues (Amber/Persimmon/Plum) from the ball palette.
    /// The token sheet intentionally leaves these to the badge (docs/design/ZEN_TOKENS.md).
    private var accent: Color {
        switch band {
        case .trivial: ZenColor.success            // moss   #6E9E62
        case .easy:    ZenColor.accent             // water  #4F9D8B
        case .medium:  Color(hex: 0xDDA63A)        // Amber
        case .hard:    Color(hex: 0xD27845)        // Persimmon
        case .expert:  Color(hex: 0xCC6B86)        // Plum
        }
    }
}

#Preview {
    ZStack {
        ZenColor.stage.ignoresSafeArea()
        VStack(spacing: ZenSpacing.lg) {
            DifficultyBadgeView(level: 1, band: .trivial)
            DifficultyBadgeView(level: 2, band: .easy)
            DifficultyBadgeView(level: 5, band: .medium)
            DifficultyBadgeView(level: 8, band: .hard)
            DifficultyBadgeView(level: 12, band: .expert)
        }
        .padding(ZenSpacing.xxl)
    }
}
