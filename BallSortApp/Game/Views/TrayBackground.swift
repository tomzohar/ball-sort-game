import SwiftUI

// Wooden tray + dark page backdrop, ported from the HTML prototype's theme (PROJECT_BRIEF, m3).
// Dumb styling only — no game logic (ADR-0001). Reuses `Color(hex:)` from BallColor+Color.swift.

/// The dark page backdrop behind the whole board.
///
/// Approximates the prototype's
/// `radial-gradient(1200px 600px at 50% -10%, #5a4634 0%, #3a2c20 45%, #241a12 100%)`:
/// a radial gradient whose centre sits just above the top edge.
struct GameBackground: View {
    var body: some View {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: 0x5A4634), location: 0.0),
                .init(color: Color(hex: 0x3A2C20), location: 0.45),
                .init(color: Color(hex: 0x241A12), location: 1.0)
            ]),
            center: UnitPoint(x: 0.5, y: -0.1),
            startRadius: 0,
            endRadius: 700
        )
        .ignoresSafeArea()
    }
}

/// A container that wraps arbitrary `content` in the prototype's wooden-tray look.
///
/// Ported CSS:
/// - background: linear-gradient(#c98a4b → #8a5a2b, top→bottom)
/// - border: 6px solid #5e3c1c
/// - border-radius: 22px
/// - box-shadow: inset 0 3px 8px rgba(255,255,255,.25),  // top highlight
///               inset 0 -8px 14px rgba(0,0,0,.45),       // bottom shadow
///               0 18px 40px rgba(0,0,0,.55)              // outer drop
///
/// SwiftUI has no native inset shadow, so the two inset shadows are approximated with
/// gradient overlays clipped to the rounded shape; the outer drop shadow uses `.shadow`.
struct WoodenTray<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private static var cornerRadius: CGFloat { 22 }
    private static var borderWidth: CGFloat { 6 }
    private static var innerPadding: CGFloat { 14 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)

        content
            .padding(Self.innerPadding)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xC98A4B), Color(hex: 0x8A5A2B)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // Inset top highlight: inset 0 3px 8px rgba(255,255,255,.25).
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.25), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .blur(radius: 4)
                .mask(shape.stroke(lineWidth: 8))
                .allowsHitTesting(false)
            )
            // Inset bottom shadow: inset 0 -8px 14px rgba(0,0,0,.45).
            .overlay(
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .blur(radius: 7)
                .mask(shape.stroke(lineWidth: 16))
                .allowsHitTesting(false)
            )
            .clipShape(shape)
            // Border: 6px solid #5e3c1c (drawn inside the clipped shape).
            .overlay(
                shape
                    .strokeBorder(Color(hex: 0x5E3C1C), lineWidth: Self.borderWidth)
                    .allowsHitTesting(false)
            )
            // Outer drop shadow: 0 18px 40px rgba(0,0,0,.55).
            .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: 18)
    }
}

#Preview {
    ZStack {
        GameBackground()
        WoodenTray {
            HStack(spacing: 14) {
                Circle().fill(Color(hex: 0xFFD21A))
                Circle().fill(Color(hex: 0xFF7A18))
                Circle().fill(Color(hex: 0x2196F3))
                Circle().fill(Color(hex: 0x36D44A))
            }
            .frame(width: 220, height: 56)
        }
        .padding(40)
    }
}
