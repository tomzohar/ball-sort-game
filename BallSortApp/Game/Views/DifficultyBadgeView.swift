import SwiftUI
import BallSortCore

/// A small pill showing the current level number and its difficulty band, e.g.
/// "Level 3 · Hard". A dumb view (ADR-0001) driven by plain values; the only Core
/// type it knows is `Difficulty.Band`.
///
/// The pill is colour-coded by band (green → easy, up to red → expert) and tuned to
/// read well on the dark, warm `GameBackground`: a translucent tinted fill, a thin
/// band-coloured border, and a matching status dot.
struct DifficultyBadgeView: View {
    /// The 1-based level number shown to the player.
    let level: Int
    /// The difficulty band of the current level.
    let band: Difficulty.Band

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)
                // A soft glow so the dot reads as a status light on the dark backdrop.
                .shadow(color: accent.opacity(0.8), radius: 3)

            Text("Level \(level)")
                .foregroundStyle(.white)

            Text("·")
                .foregroundStyle(.white.opacity(0.5))

            Text(label)
                .foregroundStyle(accent)
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(accent.opacity(0.18), in: Capsule())
        .overlay(
            Capsule().strokeBorder(accent.opacity(0.55), lineWidth: 1)
        )
        // Lift the pill slightly off the wooden tray, matching the board's depth cues.
        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
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

    /// Band accent colour: green (easy) → red (expert). Tuned to stay legible on the
    /// dark warm backdrop. Reuses `Color(hex:)` from BallColor+Color.swift.
    private var accent: Color {
        switch band {
        case .trivial: Color(hex: 0x8BD450) // light green
        case .easy:    Color(hex: 0x36D44A) // green
        case .medium:  Color(hex: 0xFFD21A) // amber
        case .hard:    Color(hex: 0xFF7A18) // orange
        case .expert:  Color(hex: 0xFF3B30) // red
        }
    }
}

#Preview {
    ZStack {
        GameBackground()
        VStack(spacing: 16) {
            DifficultyBadgeView(level: 1, band: .trivial)
            DifficultyBadgeView(level: 2, band: .easy)
            DifficultyBadgeView(level: 5, band: .medium)
            DifficultyBadgeView(level: 8, band: .hard)
            DifficultyBadgeView(level: 12, band: .expert)
        }
        .padding(40)
    }
}
