import SwiftUI
import BallSortCore

/// An in-flight pour (E14.3): a single ball travelling from a source tube's mouth to
/// the slot it lands in. Identified by `nonce` so each move animates independently.
struct PourFlight: Equatable {
    let nonce: Int
    let launch: CGPoint
    let land: CGPoint
    let color: BallColor
    let peak: CGFloat
}

/// Animates a view along the pour parabola by interpolating `progress` and translating
/// to `PourGeometry.arcPoint` each frame.
///
/// This is a `GeometryEffect` (not a `.position` animation) on purpose: animating
/// `.position` directly makes SwiftUI tween the endpoint in a straight line, throwing
/// away the arc. Driving `animatableData = progress` recomputes the curved point on
/// every interpolated frame, so the ball actually arcs over the rim.
struct PourArcEffect: GeometryEffect {
    var progress: CGFloat
    let launch: CGPoint
    let land: CGPoint
    let peak: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let point = PourGeometry.arcPoint(from: launch, to: land, peak: peak, progress: progress)
        // The flying ball is positioned at `launch`; translate it to the arc point.
        return ProjectionTransform(CGAffineTransform(translationX: point.x - launch.x, y: point.y - launch.y))
    }
}
