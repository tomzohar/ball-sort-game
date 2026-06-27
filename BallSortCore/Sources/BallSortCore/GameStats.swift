import Foundation

/// Durable, aggregate player statistics plus the daily-solve streak.
///
/// A pure value type with no notion of the wall clock: the calendar day a win
/// happened is supplied by the caller as a `yyyymmdd` `Int` key (e.g. `20260627`),
/// which keeps the model Foundation-date-free at its boundary and deterministically
/// testable. The only place `Foundation` is touched is the internal day-adjacency
/// check, which must respect month/year/leap-year rollover.
///
/// All updates are expressed as pure transformations: `recordingWin` returns a
/// brand-new `GameStats` and never mutates `self`.
public struct GameStats: Codable, Equatable, Sendable {
    /// Total number of levels solved (counts every win, including multiple wins per day).
    public var levelsSolved: Int
    /// Fewest moves used to solve any level so far, or `nil` if never solved.
    public var bestMoves: Int?
    /// Fastest solve time in seconds so far, or `nil` if never solved.
    public var bestTimeSeconds: Double?
    /// Length of the current run of consecutive calendar days with at least one win.
    public var currentStreak: Int
    /// Longest run of consecutive solving days ever achieved.
    public var longestStreak: Int
    /// The `yyyymmdd` day-key of the most recent win, or `nil` if never solved.
    public var lastSolvedDay: Int?

    /// Stats for a player who has never solved a level.
    public static let empty = GameStats(
        levelsSolved: 0,
        bestMoves: nil,
        bestTimeSeconds: nil,
        currentStreak: 0,
        longestStreak: 0,
        lastSolvedDay: nil
    )

    public init(
        levelsSolved: Int,
        bestMoves: Int?,
        bestTimeSeconds: Double?,
        currentStreak: Int,
        longestStreak: Int,
        lastSolvedDay: Int?
    ) {
        self.levelsSolved = levelsSolved
        self.bestMoves = bestMoves
        self.bestTimeSeconds = bestTimeSeconds
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastSolvedDay = lastSolvedDay
    }

    /// Returns a new `GameStats` reflecting a level solved in `moves` moves and
    /// `seconds` seconds on calendar day `day` (a `yyyymmdd` key).
    ///
    /// - `levelsSolved` always increments.
    /// - `bestMoves` / `bestTimeSeconds` only improve (lower wins).
    /// - The streak advances by one when `day` is the calendar day immediately
    ///   after `lastSolvedDay`, stays put on a same-day repeat win, and resets to
    ///   one on the first win or any non-consecutive day (including backward moves
    ///   or gaps). `longestStreak` tracks the running maximum.
    public func recordingWin(moves: Int, seconds: Double, day: Int) -> GameStats {
        var updated = self

        updated.levelsSolved += 1
        updated.bestMoves = Swift.min(bestMoves ?? moves, moves)
        updated.bestTimeSeconds = Swift.min(bestTimeSeconds ?? seconds, seconds)

        if let last = lastSolvedDay, last == day {
            // Same calendar day: another win, but the streak does not double-count.
            // currentStreak / longestStreak unchanged.
        } else if let last = lastSolvedDay, Self.isDay(day, immediatelyAfter: last) {
            updated.currentStreak += 1
        } else {
            // First win ever, a gap, or any non-consecutive day.
            updated.currentStreak = 1
        }

        updated.longestStreak = Swift.max(longestStreak, updated.currentStreak)
        updated.lastSolvedDay = day
        return updated
    }

    /// Returns a new `GameStats` with only the best-moves / best-time records
    /// improved (lower wins), leaving `levelsSolved`, the streak, and `lastSolvedDay`
    /// untouched.
    ///
    /// Used for replay/practice wins (E13): replaying a past level should be able to
    /// sharpen your records without inflating the solved count or the daily streak or
    /// advancing the difficulty curve.
    public func improvingBests(moves: Int, seconds: Double) -> GameStats {
        var updated = self
        updated.bestMoves = Swift.min(bestMoves ?? moves, moves)
        updated.bestTimeSeconds = Swift.min(bestTimeSeconds ?? seconds, seconds)
        return updated
    }

    /// Whether `day` is the calendar day immediately following `other`, where both
    /// are `yyyymmdd` keys. Correct across month, year, and leap-day boundaries
    /// because it resolves the keys to real dates via `Calendar`.
    private static func isDay(_ day: Int, immediatelyAfter other: Int) -> Bool {
        guard let otherDate = date(fromDayKey: other),
              let next = calendar.date(byAdding: .day, value: 1, to: otherDate),
              let nextKey = dayKey(from: next, in: calendar) else {
            return false
        }
        return nextKey == day
    }

    /// A fixed, locale-independent calendar (UTC, Gregorian) so day arithmetic is
    /// deterministic regardless of the host's time zone.
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    /// Resolves a `yyyymmdd` key to a `Date`, returning `nil` for an invalid date.
    private static func date(fromDayKey key: Int) -> Date? {
        let year = key / 10_000
        let month = (key / 100) % 100
        let day = key % 100
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        // `date(from:)` is lenient, so validate the round-trip rejects e.g. Feb 30.
        guard let date = calendar.date(from: components),
              dayKey(from: date, in: calendar) == key else {
            return nil
        }
        return date
    }

    /// Builds a `yyyymmdd` key from a `Date` using the given calendar.
    private static func dayKey(from date: Date, in calendar: Calendar) -> Int? {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }
        return year * 10_000 + month * 100 + day
    }
}
