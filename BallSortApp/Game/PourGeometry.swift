import CoreGraphics

/// Pure geometry for the pour-arc flight (E14.3): where a poured ball launches from,
/// where it lands, and the parabola it travels between them.
///
/// UI-free (CoreGraphics only) so the coordinate math — the part most prone to subtle
/// bugs — is unit-tested without a simulator, mirroring `BoardLayout`. SwiftUI passes
/// in the tube's resolved frame and the layout metrics; this returns points in the
/// same coordinate space.
enum PourGeometry {

    /// Centre of the slot a tube's **top ball** occupies when the tube holds `count`
    /// balls — at slot `capacity - count` from the top (balls stack bottom-up, so the
    /// filled region starts that many empty slots down).
    ///
    /// Used for both ends of a pour: the source's top ball *before* the move (the
    /// launch point, so the ball lifts off exactly where it sat — not from the mouth)
    /// and the destination's top ball *after* it lands.
    ///
    /// - Parameters:
    ///   - count: the tube's ball count at the moment of interest (≥ 1).
    static func topBallPoint(
        in tubeRect: CGRect,
        capacity: Int,
        count: Int,
        ballSize: CGFloat,
        ballGap: CGFloat
    ) -> CGPoint {
        let topSlot = max(0, capacity - max(1, count))
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
