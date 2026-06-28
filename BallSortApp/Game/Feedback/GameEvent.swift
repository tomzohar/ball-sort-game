import Foundation

/// A gameplay moment that warrants player feedback (sound and/or haptics).
/// Fired by `BoardViewModel` and consumed by `GameFeedbackPlaying` implementations
/// (E8 "Juice"). Kept UI-free so it lives alongside the view model, not in Core.
enum GameEvent: Equatable {
    /// A non-empty tube was lifted (first tap of a selection).
    case lift
    /// A ball was dropped onto a legal destination.
    case drop
    /// A move finished a tube (full, single-color).
    case tubeComplete
    /// A move was attempted and rejected by the rules.
    case illegalMove
    /// The board was solved.
    case win
    /// The last move was reverted.
    case undo
    /// The player asked for a hint and the solver surfaced one (E14.7) — a gentle
    /// "here" cue accompanying the on-board nudge.
    case hint
}
