import Foundation

/// A single completed level — one row of the player's run history (E13).
///
/// Recorded on every win. It carries the result (level number, moves, time, the
/// `yyyymmdd` day it happened) **plus the level's starting `board`**, so the exact
/// same puzzle can be replayed later — generated levels aren't otherwise
/// reproducible without persisting their seed, and a snapshot stays faithful even
/// if the generator or difficulty curve changes.
///
/// A pure value type with no notion of the wall clock: the day-key and `id` are
/// supplied by the recorder (the App-layer `HistoryStore`), keeping this model
/// Foundation-date-free at its boundary and deterministically testable.
public struct LevelRun: Codable, Equatable, Sendable, Identifiable {
    /// Stable identity for list diffing. Assigned by the recorder; two otherwise
    /// identical runs (same level/moves/time/day) remain distinguishable.
    public let id: UUID
    /// The 1-based level number that was solved.
    public var level: Int
    /// Moves used to solve it.
    public var moves: Int
    /// Solve time in seconds.
    public var timeSeconds: Double
    /// The `yyyymmdd` day-key the win happened on (e.g. `20260627`).
    public var dayKey: Int
    /// The level's starting board — what a replay loads to re-play the exact puzzle.
    public var board: GameState

    public init(
        id: UUID,
        level: Int,
        moves: Int,
        timeSeconds: Double,
        dayKey: Int,
        board: GameState
    ) {
        self.id = id
        self.level = level
        self.moves = moves
        self.timeSeconds = timeSeconds
        self.dayKey = dayKey
        self.board = board
    }
}

/// The player's ordered run history — newest first — with a bounded size (E13).
///
/// A pure value type: `recording(_:)` returns a new history with the run prepended,
/// evicting the oldest entries past `maxEntries` so the persisted JSON stays small
/// even though each run embeds a board snapshot.
public struct LevelHistory: Codable, Equatable, Sendable {
    /// Upper bound on retained runs. Each run carries a board snapshot, so this caps
    /// the persisted file size; older runs beyond it are dropped on record.
    public static let maxEntries = 200

    /// Completed runs, newest first.
    public private(set) var runs: [LevelRun]

    /// An empty history.
    public static let empty = LevelHistory(runs: [])

    public init(runs: [LevelRun]) {
        self.runs = Array(runs.prefix(Self.maxEntries))
    }

    /// Returns a new history with `run` recorded as the newest entry, evicting the
    /// oldest runs beyond `maxEntries`.
    public func recording(_ run: LevelRun) -> LevelHistory {
        LevelHistory(runs: [run] + runs)
    }
}
