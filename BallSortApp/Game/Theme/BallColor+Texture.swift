import SwiftUI
import BallSortCore

// Per-stone texture cue (E12.2, data layer). Each Zen stone carries a distinct
// surface pattern so the six balls are distinguishable by texture, not hue alone —
// this is the colorblind-safe cue for the reskin (augmenting/replacing the SF-Symbol
// badge in BallColor+Accessibility.swift). Exact stone→texture mapping from the
// canvas token sheet (docs/design/ZEN_TOKENS.md).
//
// This file owns the *mapping* (pure data, like the palette). The actual drawing of
// each pattern on the stone lives in the ZenBall view (E12.4).

/// A distinct surface pattern drawn on a river-stone, used as the colorblind cue.
enum ZenStoneTexture: String, CaseIterable, Sendable {
    case rings      // concentric rings
    case dots       // scattered dots
    case diagonal   // diagonal stripes
    case vertical   // vertical stripes
    case wave       // horizontal wave lines
    case grid       // crosshatch grid
}

extension BallColor {
    /// The Zen stone texture for this color — the per-stone colorblind cue.
    var stoneTexture: ZenStoneTexture {
        switch self {
        case .yellow: .rings     // Amber
        case .orange: .dots      // Persimmon
        case .pink:   .diagonal  // Plum
        case .green:  .vertical  // Moss
        case .blue:   .wave      // Pond
        case .purple: .grid      // Iris
        }
    }
}
