import SwiftUI
import BallSortCore

/// A single glossy gradient ball, ported from the HTML prototype's `.ball` styling.
///
/// Dumb view (ADR-0001): renders a `BallColor` at a given size; no game logic.
/// The look is stacked `RadialGradient`s over a `Circle`, mirroring the prototype's
/// CSS layers (specular highlight, color body, lower-right shading) plus a drop
/// shadow, and an optional lift treatment when the ball is picked up.
struct BallView: View {
    /// The ball's color; mapped to a SwiftUI `Color` via the App-layer palette.
    let color: BallColor
    /// The ball's diameter in points. Gradient radii scale off this so the look
    /// is identical at any size.
    let size: CGFloat
    /// When `true`, the ball is "picked up": it scales up slightly and gains a
    /// white glow ring (prototype's `.ball.lifted`).
    var isLifted: Bool = false
    /// When `true` (default), overlays a color-blind-safe SF Symbol badge so the
    /// six colors are distinguishable by shape, not hue alone (E9.4).
    var showsColorBlindBadge: Bool = true

    var body: some View {
        Circle()
            .fill(color.swiftUIColor)
            .overlay { bodyShading }       // color body, darkening to the rim
            .overlay { lowerRightShading } // shadow in the lower-right
            .overlay { specularHighlight } // bright spot, upper-left
            .overlay { colorBlindBadge }   // shape glyph for color-blind safety
            .overlay { liftRing }          // white ring when lifted
            .frame(width: size, height: size)
            .scaleEffect(isLifted ? 1.06 : 1.0)
            // Prototype drop shadow: `0 4px 6px rgba(0,0,0,.45)`.
            .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 4)
            // Prototype `.ball.lifted` outer glow: `0 0 16px 4px rgba(255,255,255,.55)`.
            .shadow(color: isLifted ? .white.opacity(0.55) : .clear, radius: 8)
            // Ease the scale/glow in/out instead of snapping (E8.3).
            .animation(AnimationConstants.ballLift, value: isLifted)
            // Collapse the decorative gradient/highlight layers into one VoiceOver
            // element that simply names the color (E9.4).
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(color.ballAccessibilityLabel)
    }

    /// Color-blind-safe cue: a small, subtly-tinted SF Symbol centered on the ball
    /// so each color reads as a distinct shape regardless of hue perception (E9.4).
    /// Purely decorative — VoiceOver ignores it via the ball's combined element.
    @ViewBuilder private var colorBlindBadge: some View {
        if showsColorBlindBadge {
            Image(systemName: color.accessibilitySymbolName)
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                .accessibilityHidden(true)
        }
    }

    /// Body: ball color held to 55%, then darkening to `black .25` at the rim.
    private var bodyShading: some View {
        Circle().fill(
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: color.swiftUIColor, location: 0.0),
                    .init(color: color.swiftUIColor, location: 0.55),
                    .init(color: .black.opacity(0.25), location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: size / 2
            )
        )
    }

    /// Shading: a soft black blob in the lower-right (`~70%,75%`), gone by ~45%.
    private var lowerRightShading: some View {
        Circle().fill(
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(0.45), location: 0.0),
                    .init(color: .clear, location: 1.0)
                ]),
                center: UnitPoint(x: 0.70, y: 0.75),
                startRadius: 0,
                endRadius: size * 0.45
            )
        )
    }

    /// Specular highlight: bright white spot at the upper-left (`~32%,28%`).
    private var specularHighlight: some View {
        Circle().fill(
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .white.opacity(0.95), location: 0.0),
                    .init(color: .white.opacity(0.25), location: 0.40),
                    .init(color: .clear, location: 1.0)
                ]),
                center: UnitPoint(x: 0.32, y: 0.28),
                startRadius: 0,
                endRadius: size * 0.30
            )
        )
    }

    /// Lift treatment: solid white ring hugging the ball (`box-shadow: 0 0 0 4px #fff`).
    @ViewBuilder private var liftRing: some View {
        if isLifted {
            Circle().strokeBorder(Color.white, lineWidth: max(2, size * 0.05))
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            ForEach(BallColor.allCases, id: \.self) { color in
                BallView(color: color, size: 56)
            }
        }
        HStack(spacing: 16) {
            BallView(color: .blue, size: 56, isLifted: true)
            BallView(color: .pink, size: 56, isLifted: true)
        }
    }
    .padding(40)
    .background(Color(white: 0.15))
}
