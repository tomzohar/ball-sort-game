import SwiftUI
import BallSortCore

// BallColor → SwiftUI Color lives in the App layer: BallSortCore stays UI-free (ADR-0001/0004).
// "Zen Garden" re-tuned 6-stone river-stone palette (E12.1). Exact hex from the canvas
// token sheet (docs/design/ZEN_TOKENS.md). The Core `BallColor` enum is unchanged —
// only this App-layer mapping. Each stone also carries a texture cue (BallColor+Texture).
extension BallColor {
    var swiftUIColor: Color {
        switch self {
        case .yellow: Color(hex: 0xDDA63A)  // Amber
        case .orange: Color(hex: 0xD27845)  // Persimmon
        case .pink:   Color(hex: 0xCC6B86)  // Plum
        case .green:  Color(hex: 0x6E9E62)  // Moss
        case .blue:   Color(hex: 0x4E8CA8)  // Pond
        case .purple: Color(hex: 0x8A77B8)  // Iris
        }
    }
}

extension Color {
    /// Build a Color from a 24-bit RGB hex literal, e.g. `Color(hex: 0xFF7A18)`.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
