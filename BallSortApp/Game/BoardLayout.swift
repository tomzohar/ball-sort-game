import CoreGraphics

/// Pure adaptive sizing for the game board, ported from the HTML prototype's JS formula.
///
/// This type is deliberately UI-free (imports only `CoreGraphics`) so it unit-tests
/// without a simulator (ADR-0001/0003). SwiftUI views consume these values; they never
/// recompute sizing themselves.
///
/// ## Stacking model
/// A tube renders `capacity` balls stacked vertically with a fixed gap between adjacent
/// balls and uniform inner padding around the column:
/// ```
/// tubeHeight = 2·verticalPadding + capacity·ballSize + (capacity − 1)·ballGap
/// tubeWidth  = 2·horizontalPadding + ballSize
/// ```
/// (`capacity` balls → `capacity − 1` interior gaps.) Ball and tube widths are equal here
/// because balls are circles sized to the tube's inner width.
enum BoardLayout {

    // MARK: - Ported spacing constants (prototype CSS)

    /// Horizontal gap between adjacent tubes.
    static let tubeGap: CGFloat = 8
    /// Vertical gap between stacked balls inside a tube.
    static let ballGap: CGFloat = 8
    /// Tube inner padding, vertical (top/bottom).
    static let tubeVerticalPadding: CGFloat = 6
    /// Tube inner padding, horizontal (leading/trailing).
    static let tubeHorizontalPadding: CGFloat = 5
    /// Tube corner radius.
    static let tubeCornerRadius: CGFloat = 16

    // MARK: - Ball-size bounds

    /// Default maximum ball diameter (compact width class, e.g. iPhone portrait).
    /// iPad / regular width passes a larger cap (~80) via `maxBall`.
    static let defaultMaxBall: CGFloat = 58
    /// Floor for the ball diameter so tubes stay tappable even at extreme widths / tube counts.
    static let minBall: CGFloat = 18

    /// Width budget subtracted from the available width before dividing among tubes
    /// (board margins / chrome), ported from the prototype.
    static let widthInset: CGFloat = 70
    /// Hard cap on the usable row width, ported from the prototype.
    static let maxRowWidth: CGFloat = 620
    /// Per-tube slack subtracted after dividing, ported from the prototype.
    static let perTubeSlack: CGFloat = 10

    // MARK: - Adaptive ball size

    /// Adaptive ball diameter for a row of tubes.
    ///
    /// Ports the prototype formula:
    /// ```js
    /// size = min(maxBall, floor(min(availableWidth - 70, 620) / tubeCount) - 10)
    /// ```
    /// The result is clamped to `[minBall, maxBall]` and is never NaN, infinite, or negative,
    /// even for tiny widths or large tube counts.
    ///
    /// - Parameters:
    ///   - availableWidth: usable width for the whole tube row (points).
    ///   - tubeCount: number of tubes in the row (treated as ≥ 1).
    ///   - maxBall: upper bound on ball diameter. Defaults to ``defaultMaxBall`` (58, compact);
    ///     callers pass a larger value (~80) for iPad / regular width.
    static func ballSize(availableWidth: CGFloat, tubeCount: Int, maxBall: CGFloat = defaultMaxBall) -> CGFloat {
        // Guard against degenerate inputs before any arithmetic.
        guard maxBall.isFinite else { return minBall }
        let cap = max(minBall, maxBall)
        let count = CGFloat(max(1, tubeCount))
        let width = availableWidth.isFinite ? availableWidth : 0

        let usable = min(width - widthInset, maxRowWidth)
        let perTube = (usable / count).rounded(.down) - perTubeSlack

        // perTube may be NaN/negative for tiny/garbage widths; clamp into [minBall, cap].
        guard perTube.isFinite else { return minBall }
        return min(cap, max(minBall, perTube))
    }

    // MARK: - Fitted ball size (fills both width and height)

    /// The largest ball diameter that fills a board area holding all `tubeCount` tubes
    /// in a **single row**, each stacking `capacity` balls — so the board stretches to
    /// fill BOTH the available width and height.
    ///
    /// Unlike ``ballSize(availableWidth:tubeCount:maxBall:)`` (width only, intrinsic
    /// height), this binds on whichever of width/height is tighter, so the board no
    /// longer leaves large unused space. Clamped to `[minBall, maxBall]` and robust to
    /// NaN/infinite/negative inputs.
    static func fittedBallSize(
        available: CGSize,
        tubeCount: Int,
        capacity: Int,
        maxBall: CGFloat
    ) -> CGFloat {
        guard available.width.isFinite, available.height.isFinite, maxBall.isFinite else { return minBall }
        let count = CGFloat(max(1, tubeCount))
        let cap = CGFloat(max(1, capacity))

        // Width: tubes share the row width with `tubeGap` between them; ball is the
        // tube's inner width (tube width minus its horizontal padding on both sides).
        let rowWidth = available.width - tubeGap * (count - 1)
        let widthFit = rowWidth / count - 2 * tubeHorizontalPadding

        // Height: the row holds one tube column of `capacity` balls plus interior gaps
        // and top/bottom padding.
        let heightFit = (available.height - 2 * tubeVerticalPadding - (cap - 1) * ballGap) / cap

        let fit = min(widthFit, heightFit)
        guard fit.isFinite else { return minBall }
        return min(max(minBall, maxBall), max(minBall, fit.rounded(.down)))
    }

    /// The vertical gap between stacked balls that stretches a tube column down to
    /// fill `availableHeight` — taller columns with more air between balls, so the
    /// board uses the vertical space instead of hugging a short stack.
    ///
    /// Falls back to the base ``ballGap`` when there's no slack, and is capped at
    /// `2×ballSize` so balls never float absurdly far apart.
    static func filledBallGap(availableHeight: CGFloat, capacity: Int, ballSize: CGFloat) -> CGFloat {
        let cap = max(1, capacity)
        guard cap > 1, availableHeight.isFinite, ballSize.isFinite else { return ballGap }
        let slack = availableHeight - 2 * tubeVerticalPadding - CGFloat(cap) * ballSize
        let gap = slack / CGFloat(cap - 1)
        let maxGap = max(ballGap, ballSize * 2)
        return min(maxGap, max(ballGap, gap))
    }

    // MARK: - Derived dimensions

    /// Tube outer width for a given ball diameter.
    static func tubeWidth(ballSize: CGFloat) -> CGFloat {
        ballSize + 2 * tubeHorizontalPadding
    }

    /// Tube outer height for a given ball diameter and capacity.
    ///
    /// `capacity` balls stacked with `capacity − 1` interior gaps plus top/bottom padding.
    /// A `capacity` of 0 yields just the padding (no balls, no gaps).
    static func tubeHeight(ballSize: CGFloat, capacity: Int) -> CGFloat {
        tubeHeight(ballSize: ballSize, capacity: capacity, ballGap: ballGap)
    }

    /// Tube outer height for a given ball diameter, capacity, and explicit inter-ball gap.
    ///
    /// `capacity` balls stacked with `capacity − 1` interior gaps plus top/bottom padding.
    /// A `capacity` of 0 yields just the padding (no balls, no gaps).
    static func tubeHeight(ballSize: CGFloat, capacity: Int, ballGap: CGFloat) -> CGFloat {
        let n = max(0, capacity)
        let balls = CGFloat(n) * ballSize
        let gaps = CGFloat(max(0, n - 1)) * ballGap
        return balls + gaps + 2 * tubeVerticalPadding
    }
}
