import Foundation
import Observation
import BallSortCore

/// Owns the durable `GameStats` and the seam that records wins into them (E7.2,
/// E7.3). An `@Observable` so the stats screen reflects updates live.
///
/// Stats are loaded from the injected `PersistenceStore` on construction and
/// re-saved after every recorded win. The "today" day-key is injected as a
/// closure so streak logic is deterministically testable without the wall clock;
/// the default derives a `yyyymmdd` key from the current calendar day. A `nil`
/// store (the default) makes a non-persisting instance for previews and tests.
@MainActor
@Observable
final class StatsStore {
    /// The current aggregate stats. Starts at `.empty` when nothing is persisted.
    private(set) var stats: GameStats

    private let persistence: (any PersistenceStore)?
    private let today: () -> Int

    init(
        persistence: (any PersistenceStore)? = nil,
        today: @escaping () -> Int = StatsStore.currentDayKey
    ) {
        self.persistence = persistence
        self.today = today
        if let persistence,
           let loaded = try? persistence.load(GameStats.self, forKey: PersistenceKeys.stats) {
            self.stats = loaded ?? .empty
        } else {
            self.stats = .empty
        }
    }

    /// Record a solved level — updating counts, records, and the daily streak —
    /// and persist the result. Called by `BoardViewModel` on win.
    func recordWin(moves: Int, seconds: TimeInterval) {
        stats = stats.recordingWin(moves: moves, seconds: seconds, day: today())
        try? persistence?.save(stats, forKey: PersistenceKeys.stats)
    }

    /// The current calendar day as a `yyyymmdd` key, in the user's local calendar.
    static func currentDayKey() -> Int {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return (components.year ?? 0) * 10_000
            + (components.month ?? 0) * 100
            + (components.day ?? 0)
    }
}
