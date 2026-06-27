import SwiftUI
import BallSortCore

/// A single "Zen Garden" river-stone (E12.4): a polished, frosted stone in the
/// ball's palette color, carrying a per-stone surface texture as the colorblind cue.
///
/// Dumb view (ADR-0001): renders a `BallColor` at a given size; no game logic.
/// The look is a frosted body (palette color softened toward a frosted-glass
/// surface), a soft gloss highlight in the upper-left, a hairline `ZenColor.stoneFrame`
/// rim, and `ZenShadow.rest` underneath. The stone's texture (`color.stoneTexture`)
/// is drawn on top — concentric rings / scattered dots / diagonal stripes / vertical
/// stripes / horizontal wave lines / crosshatch grid — so the six colors are
/// distinguishable by pattern, not hue alone (E12.2). The texture replaces the old
/// SF-Symbol badge as the colorblind cue.
struct BallView: View {
    /// The ball's color; mapped to a SwiftUI `Color` via the App-layer palette.
    let color: BallColor
    /// The ball's diameter in points. All gloss/texture geometry scales off this so
    /// the look is identical at any size.
    let size: CGFloat
    /// When `true`, the stone is "picked up": it scales up slightly and gains a soft
    /// light glow ring (Zen lifted state).
    var isLifted: Bool = false
    /// When `true`, the stone sits in a legal destination and gains a calm accent
    /// glow (Zen valid-target state). Defaults to `false` so existing callers
    /// (TubeView/BoardView) are unaffected — target highlighting is driven at the
    /// tube level; this is the optional per-stone cue.
    var isValidTarget: Bool = false
    /// When `true` (default), draws the per-stone texture cue so the six colors are
    /// distinguishable by pattern, not hue alone (E12.2). When `false`, the stone is
    /// drawn plain (used to isolate the body in tests / previews).
    var showsColorBlindBadge: Bool = true

    var body: some View {
        Circle()
            .fill(frostedBody)             // frosted stone body in the palette color
            .overlay { rimShading }        // soft darkening toward the rim
            .overlay { stoneTexture }      // colorblind cue: per-stone surface pattern
            .overlay { gloss }             // polished gloss highlight, upper-left
            .overlay { rim }               // hairline Zen stone-frame border
            .overlay { liftRing }          // light ring when lifted
            .frame(width: size, height: size)
            .scaleEffect(isLifted ? 1.06 : 1.0)
            // Resting elevation: a whisper of depth under the stone (ZenShadow.rest).
            .zenShadow(.rest)
            // Lifted: a soft light halo. Valid target: a calm accent halo. Both ease.
            .shadow(color: liftGlowColor, radius: isLifted ? 10 : 0)
            .shadow(color: targetGlowColor, radius: isValidTarget ? 9 : 0)
            // Ease the scale/glow in/out instead of snapping (E8.3 / Zen motion).
            .animation(AnimationConstants.ballLift, value: isLifted)
            .animation(AnimationConstants.ballLift, value: isValidTarget)
            // Collapse the decorative layers into one VoiceOver element that names the
            // color — the texture is the *visual* cue; the spoken name is unchanged.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(color.ballAccessibilityLabel)
    }

    // MARK: - Body & shading

    /// Frosted stone body: the palette color held in the center, lightened a touch
    /// toward a frosted-glass surface as it spreads — calm and matte rather than the
    /// old glossy candy ball.
    private var frostedBody: RadialGradient {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: color.swiftUIColor.opacity(0.96), location: 0.0),
                .init(color: color.swiftUIColor.opacity(0.88), location: 0.62),
                .init(color: color.swiftUIColor.opacity(0.78), location: 1.0)
            ]),
            center: UnitPoint(x: 0.42, y: 0.40),
            startRadius: 0,
            endRadius: size * 0.62
        )
    }

    /// Rim shading: a soft darkening that hugs the lower-right edge, giving the stone
    /// a rounded, weighted feel without the prototype's hard specular contrast.
    private var rimShading: some View {
        Circle().fill(
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0.55),
                    .init(color: .black.opacity(0.18), location: 1.0)
                ]),
                center: UnitPoint(x: 0.62, y: 0.66),
                startRadius: 0,
                endRadius: size * 0.62
            )
        )
    }

    /// Polished gloss: a soft, diffuse highlight in the upper-left — a frosted sheen,
    /// not a sharp specular dot.
    private var gloss: some View {
        Circle().fill(
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .white.opacity(0.55), location: 0.0),
                    .init(color: .white.opacity(0.14), location: 0.45),
                    .init(color: .clear, location: 1.0)
                ]),
                center: UnitPoint(x: 0.34, y: 0.30),
                startRadius: 0,
                endRadius: size * 0.40
            )
        )
        .blendMode(.softLight)
    }

    /// Hairline stone frame: a subtle inner border in the Zen frame tone (E12.0),
    /// matching tubes/cards so the whole reskin reads as one material.
    private var rim: some View {
        Circle().strokeBorder(ZenColor.stoneFrame.opacity(0.55), lineWidth: max(1, size * 0.02))
    }

    /// Lift treatment: a soft white ring hugging the stone when picked up.
    @ViewBuilder private var liftRing: some View {
        if isLifted {
            Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: max(2, size * 0.045))
        }
    }

    // MARK: - Glows

    /// Soft light halo when lifted (Zen lifted state); inert otherwise.
    private var liftGlowColor: Color { isLifted ? .white.opacity(0.45) : .clear }

    /// Calm accent halo when this stone is a valid drop target; inert otherwise.
    private var targetGlowColor: Color { isValidTarget ? ZenColor.accent.opacity(0.55) : .clear }

    // MARK: - Texture (colorblind cue, E12.2)

    /// The per-stone surface pattern, drawn on the stone and clipped to the circle.
    /// Each `ZenStoneTexture` renders a visually distinct motif so the six colors are
    /// told apart by pattern, not hue. Purely decorative — VoiceOver ignores it.
    @ViewBuilder private var stoneTexture: some View {
        if showsColorBlindBadge {
            ZenStoneTextureShape(texture: color.stoneTexture)
                .stroke(textureInk, lineWidth: max(1, size * 0.028))
                .clipShape(Circle().inset(by: size * 0.06))
                .accessibilityHidden(true)
        }
    }

    /// Texture ink: a low-contrast tone that sits on the stone without shouting —
    /// dark enough to read on the muted palette, soft enough to stay calm.
    private var textureInk: Color { Color.black.opacity(0.28) }
}

/// Draws one of the six Zen stone textures within its rect, sized to that rect so it
/// scales cleanly with the stone. The drawing is the visual half of the cue; the
/// stone→texture *mapping* lives in `BallColor+Texture.swift`.
private struct ZenStoneTextureShape: Shape {
    let texture: ZenStoneTexture

    func path(in rect: CGRect) -> Path {
        switch texture {
        case .rings:    return Self.rings(in: rect)
        case .dots:     return Self.dots(in: rect)
        case .diagonal: return Self.diagonal(in: rect)
        case .vertical: return Self.vertical(in: rect)
        case .wave:     return Self.wave(in: rect)
        case .grid:     return Self.grid(in: rect)
        }
    }

    /// Concentric rings (Amber).
    private static func rings(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxR = min(rect.width, rect.height) / 2
        for i in 1...3 {
            let r = maxR * (CGFloat(i) / 3.4)
            path.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
        }
        return path
    }

    /// Scattered dots on a staggered grid (Persimmon).
    private static func dots(in rect: CGRect) -> Path {
        var path = Path()
        let dotR = min(rect.width, rect.height) * 0.055
        let stepX = rect.width / 4
        let stepY = rect.height / 4
        for row in 1...3 {
            for col in 1...3 {
                let offset = (row % 2 == 0) ? stepX * 0.5 : 0 // stagger alternate rows
                let x = rect.minX + stepX * CGFloat(col) + offset
                let y = rect.minY + stepY * CGFloat(row)
                guard x - dotR > rect.minX, x + dotR < rect.maxX else { continue }
                path.addEllipse(in: CGRect(x: x - dotR, y: y - dotR, width: dotR * 2, height: dotR * 2))
            }
        }
        return path
    }

    /// Diagonal stripes, top-left → bottom-right (Plum).
    private static func diagonal(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / 5
        var offset = -rect.height
        while offset < rect.width {
            path.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + offset + rect.height, y: rect.maxY))
            offset += step
        }
        return path
    }

    /// Vertical stripes (Moss).
    private static func vertical(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / 5
        var x = rect.minX + step
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += step
        }
        return path
    }

    /// Horizontal wave lines (Pond).
    private static func wave(in rect: CGRect) -> Path {
        var path = Path()
        let stepY = rect.height / 4
        let amplitude = rect.height * 0.05
        let segments = 8
        for row in 1...3 {
            let baseY = rect.minY + stepY * CGFloat(row)
            path.move(to: CGPoint(x: rect.minX, y: baseY))
            for seg in 1...segments {
                let t = CGFloat(seg) / CGFloat(segments)
                let y = baseY + sin(t * .pi * 4) * amplitude
                path.addLine(to: CGPoint(x: rect.minX + rect.width * t, y: y))
            }
        }
        return path
    }

    /// Crosshatch grid (Iris).
    private static func grid(in rect: CGRect) -> Path {
        var path = Path()
        let step = rect.width / 5
        var x = rect.minX + step
        while x < rect.maxX {
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
            x += step
        }
        var y = rect.minY + step
        while y < rect.maxY {
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
            y += step
        }
        return path
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
            BallView(color: .green, size: 56, isValidTarget: true)
            BallView(color: .pink, size: 56, showsColorBlindBadge: false)
        }
    }
    .padding(40)
    .background(ZenColor.sandBed)
}
