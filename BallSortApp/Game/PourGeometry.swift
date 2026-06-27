import CoreGraphics

/// Pure geometry for the pour-arc flight (E14.3): where a poured ball launches from,
/// where it lands, and the parabola it travels between them.
///
/// UI-free (CoreGraphics only) so the coordinate math — the part most prone to subtle
/// bugs — is unit-tested without a simulator, mirroring `BoardLayout`. SwiftUI passes
/// in the tube's resolved frame and the layout metrics; this returns points in the
/// same coordinate space.
enum PourGeometry {

    /// Centre of a tube's mouth (its top slot) — where a lifted ball pours out from.
    /// Independent of fill, so it reads as pouring from the rim regardless of depth.
    static func mouthPoint(in tubeRect: CGRect, ballSize: CGFloat) -> CGPoint {
        CGPoint(
            x: tubeRect.midX,
            y: tubeRect.minY + BoardLayout.tubeVerticalPadding + ballSize / 2
        )
    }

    /// Centre of the slot a poured ball comes to rest in — the destination's new top
    /// ball, at slot `capacity - countAfterMove` from the top (balls stack bottom-up,
    /// so the filled region starts that many empty slots down).
    ///
    /// - Parameters:
    ///   - countAfterMove: the destination tube's ball count *after* the move lands.
    static func landingPoint(
        in tubeRect: CGRect,
        capacity: Int,
        countAfterMove: Int,
        ballSize: CGFloat,
        ballGap: CGFloat
    ) -> CGPoint {
        let topSlot = max(0, capacity - max(1, countAfterMove))
        let y = tubeRect.minY
            + BoardLayout.tubeVerticalPadding
            + CGFloat(topSlot) * (ballSize + ballGap)
            + ballSize / 2
        return CGPoint(x: tubeRect.midX, y: y)
    }

    /// A point along the pour parabola at `progress` (0 = launch, 1 = land). The ball
    /// travels in a straight line in x while a symmetric parabolic lift raises it
    /// `peak` points above that line at the midpoint — an over-the-rim arc, not a slide.
    static func arcPoint(from launch: CGPoint, to land: CGPoint, peak: CGFloat, progress: CGFloat) -> CGPoint {
        let t = min(1, max(0, progress))
        let x = launch.x + (land.x - launch.x) * t
        let baseY = launch.y + (land.y - launch.y) * t
        // 4·t·(1−t) peaks at 1.0 when t = 0.5 and is 0 at both ends; subtract to lift (y grows downward).
        let lift = peak * 4 * t * (1 - t)
        return CGPoint(x: x, y: baseY - lift)
    }
}
