import Foundation
import Observation
import BallSortCore

/// Owns the durable per-level run history and the seam that records wins into it
/// (E13). An `@Observable` so the history screen reflects new runs live.
///
/// History is loaded from the injected `PersistenceStore` on construction and
/// re-saved after every recorded run. The "today" day-key and the run `id` factory
/// are injected as closures so recording is deterministically testable without the
/// wall clock or random UUIDs; the defaults use the current calendar day and a fresh
/// `UUID`. A `nil` store (the default) makes a non-persisting instance for previews
/// and tests.
@MainActor
@Observable
final class HistoryStore {
    /// The current run history, newest first. Starts empty when nothing is persisted.
    private(set) var history: LevelHistory

    private let persistence: (any PersistenceStore)?
    private let today: () -> Int
    private let makeID: () -> UUID

    init(
        persistence: (any PersistenceStore)? = nil,
        today: @escaping () -> Int = StatsStore.currentDayKey,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.persistence = persistence
        self.today = today
        self.makeID = makeID
        if let persistence,
           let loaded = try? persistence.load(LevelHistory.self, forKey: PersistenceKeys.history) {
            self.history = loaded ?? .empty
        } else {
            self.history = .empty
        }
    }

    /// Record a solved level — capturing its starting `board` for later replay — and
    /// persist the result. Called by `BoardViewModel` on win.
    func record(level: Int, board: GameState, moves: Int, seconds: TimeInterval) {
        let run = LevelRun(
            id: makeID(),
            level: level,
            moves: moves,
            timeSeconds: seconds,
            dayKey: today(),
            board: board
        )
        history = history.recording(run)
        try? persistence?.save(history, forKey: PersistenceKeys.history)
    }
}
