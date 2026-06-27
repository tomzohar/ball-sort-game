import Foundation
import Testing
@testable import BallSortCore

@Suite("GameStats")
struct GameStatsTests {
    // MARK: - First win

    @Test("first win from .empty sets counters, bests, and streak")
    func firstWin() {
        let stats = GameStats.empty.recordingWin(moves: 12, seconds: 30.5, day: 20260627)
        #expect(stats.levelsSolved == 1)
        #expect(stats.bestMoves == 12)
        #expect(stats.bestTimeSeconds == 30.5)
        #expect(stats.currentStreak == 1)
        #expect(stats.longestStreak == 1)
        #expect(stats.lastSolvedDay == 20260627)
    }

    // MARK: - Best moves / time only improve

    @Test("a worse later result does not overwrite the bests")
    func worseResultKeepsBest() {
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20260627)
        let second = first.recordingWin(moves: 20, seconds: 45.0, day: 20260628)
        #expect(second.bestMoves == 12)
        #expect(second.bestTimeSeconds == 30.0)
        #expect(second.levelsSolved == 2)
    }

    @Test("a better later result improves the bests")
    func betterResultUpdatesBest() {
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20260627)
        let second = first.recordingWin(moves: 8, seconds: 22.0, day: 20260628)
        #expect(second.bestMoves == 8)
        #expect(second.bestTimeSeconds == 22.0)
    }

    @Test("bests can improve independently (better moves, worse time)")
    func bestsImproveIndependently() {
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 20.0, day: 20260627)
        let second = first.recordingWin(moves: 8, seconds: 50.0, day: 20260628)
        #expect(second.bestMoves == 8)       // improved
        #expect(second.bestTimeSeconds == 20.0) // unchanged (worse time)
    }

    // MARK: - Same-day second win

    @Test("same-day second win: streak unchanged, levelsSolved increments")
    func sameDaySecondWin() {
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20260627)
        let second = first.recordingWin(moves: 10, seconds: 25.0, day: 20260627)
        #expect(second.levelsSolved == 2)
        #expect(second.currentStreak == 1)
        #expect(second.longestStreak == 1)
        #expect(second.lastSolvedDay == 20260627)
        #expect(second.bestMoves == 10) // bests still track best across the day
    }

    // MARK: - Consecutive-day wins

    @Test("consecutive day within a month increments the streak")
    func consecutiveDaySameMonth() {
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20260627)
        let second = first.recordingWin(moves: 12, seconds: 30.0, day: 20260628)
        #expect(second.currentStreak == 2)
        #expect(second.longestStreak == 2)
        #expect(second.lastSolvedDay == 20260628)
    }

    @Test("consecutive day across a month boundary increments the streak")
    func consecutiveDayMonthBoundary() {
        // 31 Jan 2026 -> 1 Feb 2026
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20260131)
        let second = first.recordingWin(moves: 12, seconds: 30.0, day: 20260201)
        #expect(second.currentStreak == 2)
        #expect(second.longestStreak == 2)
        #expect(second.lastSolvedDay == 20260201)
    }

    @Test("consecutive day across a year boundary increments the streak")
    func consecutiveDayYearBoundary() {
        // 31 Dec 2026 -> 1 Jan 2027
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20261231)
        let second = first.recordingWin(moves: 12, seconds: 30.0, day: 20270101)
        #expect(second.currentStreak == 2)
        #expect(second.longestStreak == 2)
        #expect(second.lastSolvedDay == 20270101)
    }

    @Test("consecutive day across a leap-day boundary increments the streak")
    func consecutiveDayLeapBoundary() {
        // 2028 is a leap year: 28 Feb -> 29 Feb -> 1 Mar
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20280228)
        let second = first.recordingWin(moves: 12, seconds: 30.0, day: 20280229)
        let third = second.recordingWin(moves: 12, seconds: 30.0, day: 20280301)
        #expect(second.currentStreak == 2)
        #expect(third.currentStreak == 3)
        #expect(third.lastSolvedDay == 20280301)
    }

    // MARK: - Gaps

    @Test("a gap of more than one day resets the streak to 1")
    func gapResetsStreak() {
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20260627)
        let second = first.recordingWin(moves: 12, seconds: 30.0, day: 20260628) // streak 2
        let third = second.recordingWin(moves: 12, seconds: 30.0, day: 20260701) // gap
        #expect(third.currentStreak == 1)
        #expect(third.longestStreak == 2) // longest preserved
        #expect(third.lastSolvedDay == 20260701)
    }

    @Test("a same-month two-day gap resets the streak")
    func twoDayGapResets() {
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20260627)
        let second = first.recordingWin(moves: 12, seconds: 30.0, day: 20260629) // skipped 28th
        #expect(second.currentStreak == 1)
    }

    @Test("a win earlier than the last solved day (non-consecutive) resets to 1")
    func backwardsDayResets() {
        let first = GameStats.empty.recordingWin(moves: 12, seconds: 30.0, day: 20260628)
        let second = first.recordingWin(moves: 12, seconds: 30.0, day: 20260627)
        #expect(second.currentStreak == 1)
        #expect(second.lastSolvedDay == 20260627)
    }

    // MARK: - Longest streak across rise-then-reset

    @Test("longestStreak tracks the max across a rise-then-reset sequence")
    func longestStreakTracksMax() {
        var stats = GameStats.empty
        stats = stats.recordingWin(moves: 1, seconds: 1, day: 20260601) // streak 1
        stats = stats.recordingWin(moves: 1, seconds: 1, day: 20260602) // streak 2
        stats = stats.recordingWin(moves: 1, seconds: 1, day: 20260603) // streak 3
        #expect(stats.currentStreak == 3)
        #expect(stats.longestStreak == 3)
        stats = stats.recordingWin(moves: 1, seconds: 1, day: 20260610) // gap -> reset
        #expect(stats.currentStreak == 1)
        #expect(stats.longestStreak == 3) // max preserved
        stats = stats.recordingWin(moves: 1, seconds: 1, day: 20260611) // streak 2
        #expect(stats.currentStreak == 2)
        #expect(stats.longestStreak == 3)
    }

    // MARK: - Purity

    @Test("recordingWin does not mutate the receiver")
    func recordingWinIsPure() {
        let original = GameStats.empty
        _ = original.recordingWin(moves: 5, seconds: 5.0, day: 20260627)
        #expect(original == GameStats.empty)
    }

    // MARK: - Codable round-trip

    @Test("Codable round-trip preserves equality")
    func codableRoundTrip() throws {
        let stats = GameStats.empty
            .recordingWin(moves: 12, seconds: 30.5, day: 20260627)
            .recordingWin(moves: 8, seconds: 22.0, day: 20260628)
        let data = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)
        #expect(decoded == stats)
    }

    @Test("empty Codable round-trip preserves equality")
    func emptyCodableRoundTrip() throws {
        let data = try JSONEncoder().encode(GameStats.empty)
        let decoded = try JSONDecoder().decode(GameStats.self, from: data)
        #expect(decoded == GameStats.empty)
    }
}
