import BallSortCore

/// A just-applied move, surfaced by `BoardViewModel` for the pour-arc flight (E14.3).
///
/// Pure value type: the source and destination tube indices, the color of the ball
/// that travelled, and a monotonic `nonce`. The view keys its one-shot flight on
/// `nonce` so two moves with the same endpoints still each animate.
struct AnimatedMove: Equatable {
    let from: Int
    let to: Int
    let color: BallColor
    let nonce: Int
}
