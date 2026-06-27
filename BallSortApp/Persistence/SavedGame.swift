import Foundation
import BallSortCore

/// A persisted snapshot of an in-progress level, enough to restore the board the
/// player left mid-solve on the next launch (E7.1).
///
/// The undo history is intentionally dropped — restoring the current board, its
/// starting board (for restart), the move count, and the elapsed clock is enough
/// to resume play; rebuilding a full undo stack across launches isn't worth the
/// size. Persisted as JSON behind `PersistenceStore` (ADR-0002), so every stored
/// field is a `Codable` value type from `BallSortCore`.
struct SavedGame: Codable, Equatable, Sendable {
    /// The 1-based level the player is on.
    var level: Int
    /// The current board.
    var gameState: GameState
    /// The level's starting board — what `restart()` resets to.
    var initialState: GameState
    /// Net moves applied on this level so far.
    var moveCount: Int
    /// Seconds elapsed on this level at the moment of the snapshot.
    var elapsedSeconds: TimeInterval
}
