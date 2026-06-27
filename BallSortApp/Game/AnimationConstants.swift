import SwiftUI

/// Single source of truth for gameplay animation timing (E8.3 "Juice").
///
/// Keeping every spring/duration here keeps the views dumb (ADR-0001): a view
/// only references a named animation and drives it from observed VM state, never
/// hand-tuning timing inline. Tune the feel of the whole game from one place.
enum AnimationConstants {
    /// Selected top ball easing up/down on lift (`translateY(-10px)` + scale/glow).
    static let ballLift: Animation = .spring(response: 0.22, dampingFraction: 0.7)

    /// Bouncy spring approximating the prototype drop easing
    /// `cubic-bezier(.34, 1.4, .5, 1)` over ~0.28s. Applied around each tap.
    static let drop: Animation = .spring(response: 0.28, dampingFraction: 0.62)

    /// Snappy back-and-forth used for the illegal-move shake.
    static let shake: Animation = .spring(response: 0.18, dampingFraction: 0.35)

    /// Scale-bounce + glow pulse when a tube becomes complete.
    static let tubeCompleteFlourish: Animation = .spring(response: 0.34, dampingFraction: 0.45)

    /// Cascade entrance for the win overlay (emoji bounce, stats/buttons pop-in).
    static let winCelebration: Animation = .spring(response: 0.5, dampingFraction: 0.6)

    /// Per-element delay step for the win-overlay staggered entrance.
    static let winStagger: Double = 0.08
}
