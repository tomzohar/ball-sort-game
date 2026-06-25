import SwiftUI
import BallSortCore

// BallColor → SwiftUI Color lives in the App layer: BallSortCore stays UI-free (ADR-0001/0004).
// Palette ported from the prototype's wooden-tray theme (PROJECT_BRIEF, m3).
extension BallColor {
    var swiftUIColor: Color {
        switch self {
        case .yellow: Color(hex: 0xFFD21A)
        case .orange: Color(hex: 0xFF7A18)
        case .pink:   Color(hex: 0xFF1F8E)
        case .green:  Color(hex: 0x36D44A)
        case .blue:   Color(hex: 0x2196F3)
        case .purple: Color(hex: 0xA855F7)
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
