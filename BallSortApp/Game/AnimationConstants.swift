import SwiftUI

/// Single source of truth for gameplay animation timing (E8.3 "Juice", re-tuned for
/// the Zen Garden motion language in E12.15).
///
/// Keeping every spring/duration here keeps the views dumb (ADR-0001): a view
/// only references a named animation and drives it from observed VM state, never
/// hand-tuning timing inline. Tune the feel of the whole game from one place.
///
/// Zen motion language (docs/design/ZEN_TOKENS.md): **calm, weighted, water-like —
/// gentle settles, never bouncy or frantic.** The springs below are tuned to the
/// canvas specs: higher damping than the old prototype feel, so motion settles
/// softly rather than overshooting.
enum AnimationConstants {
    /// Lift: ball eases up ~10pt over the tube mouth. Canvas: response .22, damp .80, ~180ms.
    static let ballLift: Animation = .spring(response: 0.22, dampingFraction: 0.80)

    /// Drop: falls and settles with one soft rebound. Canvas: response .30, damp .72, ~300ms.
    static let drop: Animation = .spring(response: 0.30, dampingFraction: 0.72)

    /// Pour (E14.3): a ball arcs from the source mouth over the rim into the
    /// destination. An ease-in-out timing curve so it lifts off and settles gently
    /// (the Zen "water-like" motion), paired with `pourDuration` to time the landing.
    /// TUNABLE: duration, curve, and the arc peak (see `BoardView.pourArcPeak`) are the
    /// feel knobs to adjust on device.
    static let pour: Animation = .timingCurve(0.4, 0.0, 0.35, 1.0, duration: pourDuration)
    /// Wall-clock length of the pour flight; the view clears the flying ball after it.
    static let pourDuration: Double = 0.42

    /// Illegal move: tube shivers ±3pt, quick and quiet, no bounce-back.
    /// Canvas: shake 3 cycles ~180ms. Higher damping than before kills the rebound.
    static let shake: Animation = .spring(response: 0.18, dampingFraction: 0.55)

    /// Tube complete: a sand ripple radiates and the tube glows once.
    /// Canvas: ripple scale .4→1.8, glow pulse ~600ms.
    static let tubeCompleteFlourish: Animation = .spring(response: 0.40, dampingFraction: 0.72)

    /// Win: ripples cross the bed; card fades up, stats stagger in.
    /// Canvas: cascade, damp .70. Calm settle rather than a bouncy pop.
    static let winCelebration: Animation = .spring(response: 0.5, dampingFraction: 0.70)

    /// Per-element delay step for the win-overlay staggered entrance. Canvas: 80ms.
    static let winStagger: Double = 0.08

    /// Generating: a single rake line sweeps the empty bed, looping. Canvas: ease-in-out ~1.6s.
    static let generatingSweep: Animation = .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
}
