import Foundation

/// Stable keys for the values the app persists through a `PersistenceStore`
/// (ADR-0002). Each maps to one JSON file under the store's base directory.
enum PersistenceKeys {
    /// The in-progress level snapshot (`SavedGame`) — restored on relaunch.
    static let savedGame = "saved-game"
    /// Durable aggregate `GameStats` (levels solved, records, streak).
    static let stats = "stats"
    /// The player's per-level run history (`LevelHistory`) — E13.
    static let history = "history"
}
