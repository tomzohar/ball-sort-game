import Foundation

/// Plays player feedback (sound, haptics) for a `GameEvent`. Injected into
/// `BoardViewModel` so tests and snapshots can substitute `NoFeedback` and never
/// spin up audio/haptics hardware (E8 "Juice").
@MainActor
protocol GameFeedbackPlaying {
    func play(_ event: GameEvent)
}

/// A no-op `GameFeedbackPlaying` for tests, previews, and snapshots.
struct NoFeedback: GameFeedbackPlaying {
    func play(_ event: GameEvent) {}
}
