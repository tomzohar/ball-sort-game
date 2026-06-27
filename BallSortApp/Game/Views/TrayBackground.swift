import SwiftUI

// Raked-sand garden bed + bright "stage" backdrop — the "Zen Garden" reskin (E12.6).
// Replaces the prototype's wooden tray / dark backdrop. Dumb styling only, no game
// logic (ADR-0001). Light is the hero appearance; tokens come from `ZenTheme`.
//
// Public symbols (`GameBackground`, `WoodenTray<Content>`) keep their exact names and
// generic API so `RootView` and the snapshot tests keep compiling — only the look
// changes. `ZenTray` is offered as a forward-looking alias.

/// The bright page backdrop behind the whole board — the calm "stage" the garden
/// sits on (`ZenColor.stage`).
struct GameBackground: View {
    var body: some View {
        ZenColor.stage
            .ignoresSafeArea()
    }
}

/// A container that wraps arbitrary `content` in the raked-sand garden bed.
///
/// A `ZenColor.sandBed` surface with a subtle raked-line texture, a hairline
/// `ZenColor.stoneFrame` border, `ZenRadius.lg` rounding and a soft `ZenShadow.card`
/// lift — the puzzle's tubes rest in this bed.
///
/// Named `WoodenTray` for source compatibility with existing callers/tests; the look
/// is fully Zen. Prefer the `ZenTray` alias in new code.
struct WoodenTray<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private static var cornerRadius: CGFloat { ZenRadius.lg }
    private static var borderWidth: CGFloat { 1 }
    private static var innerPadding: CGFloat { ZenSpacing.lg }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)

        content
            .padding(Self.innerPadding)
            .background(ZenColor.sandBed)
            // Subtle raked-sand grooves combed across the bed.
            .background(RakedSand().allowsHitTesting(false))
            .clipShape(shape)
            // Hairline stone frame around the bed.
            .overlay(
                shape
                    .strokeBorder(ZenColor.stoneFrame, lineWidth: Self.borderWidth)
                    .allowsHitTesting(false)
            )
            // Soft card-level lift off the stage.
            .zenShadow(.card)
    }
}

/// Forward-looking alias for the raked-sand garden bed. Identical to `WoodenTray`;
/// new code should prefer this name.
typealias ZenTray<Content: View> = WoodenTray<Content>

/// The raked-sand groove texture: evenly combed horizontal lines, very low contrast,
/// the way a garden rake leaves the sand. Drawn with `Canvas` so it scales to any size
/// and stays a pure visual (no layout cost on the content).
private struct RakedSand: View {
    /// Spacing between rake grooves.
    private let lineSpacing: CGFloat = 9
    /// Groove stroke width.
    private let lineWidth: CGFloat = 1

    var body: some View {
        Canvas { context, size in
            // Two-tone grooves: a faint dark trough with a lighter crest just below,
            // so the rake lines read as carved grooves rather than flat stripes.
            let trough = Color.black.opacity(0.06)
            let crest = Color.white.opacity(0.30)

            var y: CGFloat = lineSpacing
            while y < size.height {
                var groove = Path()
                groove.move(to: CGPoint(x: 0, y: y))
                groove.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(groove, with: .color(trough), lineWidth: lineWidth)

                var highlight = Path()
                highlight.move(to: CGPoint(x: 0, y: y + lineWidth))
                highlight.addLine(to: CGPoint(x: size.width, y: y + lineWidth))
                context.stroke(highlight, with: .color(crest), lineWidth: lineWidth)

                y += lineSpacing
            }
        }
    }
}

#Preview {
    ZStack {
        GameBackground()
        WoodenTray {
            HStack(spacing: 14) {
                Circle().fill(BallColorPreview.amber)
                Circle().fill(BallColorPreview.persimmon)
                Circle().fill(BallColorPreview.pond)
                Circle().fill(BallColorPreview.moss)
            }
            .frame(width: 220, height: 56)
        }
        .padding(40)
    }
}

/// Stone hexes for the preview only (the real mapping lives in `BallColor+Color`).
private enum BallColorPreview {
    static let amber = Color(hex: 0xDDA63A)
    static let persimmon = Color(hex: 0xD27845)
    static let pond = Color(hex: 0x4E8CA8)
    static let moss = Color(hex: 0x6E9E62)
}
