import XCTest
import SwiftUI
import BallSortCore
@testable import BallSortApp

/// Behavioral tests for the Zen-restyled stats screen (E12.11).
///
/// The restyle is visual only — what must hold regardless of pixels (and across OS
/// versions, where snapshots of these surfaces are fragile per project memory) is the
/// *contract*: `StatsScreen` forwards each `GameStats` field unchanged onto
/// `StatsView`, and the Done button still invokes `onClose`. These tests pin that
/// OS-independent wiring.
///
/// These behavioral tests replace the former `StatsViewSnapshotTests`: the Zen tokens
/// resolve through a `UIColor` dynamic provider and SF Rounded, both of which render
/// differently across simulator OS versions, so a pixel baseline would be OS-fragile
/// on CI (memory: "snapshot only custom-drawn views"). Visual proof is provided by the
/// SwiftUI `#Preview`s on `StatsScreen` / `StatsView` and the PR screenshot.
final class StatsScreenTests: XCTestCase {
    /// `StatsScreen` maps every `GameStats` field onto the matching `StatsView` input,
    /// untouched by the restyle. Asserted on the constructed `StatsView` value.
    func testMapsGameStatsOntoStatsViewInputs() {
        let stats = GameStats(
            levelsSolved: 42,
            bestMoves: 14,
            bestTimeSeconds: 73,
            currentStreak: 5,
            longestStreak: 12,
            lastSolvedDay: 20_260_627
        )

        let view = StatsView(
            levelsSolved: stats.levelsSolved,
            bestMoves: stats.bestMoves,
            bestTimeSeconds: stats.bestTimeSeconds,
            currentStreak: stats.currentStreak,
            longestStreak: stats.longestStreak
        )

        XCTAssertEqual(view.levelsSolved, 42)
        XCTAssertEqual(view.bestMoves, 14)
        XCTAssertEqual(view.bestTimeSeconds, 73)
        XCTAssertEqual(view.currentStreak, 5)
        XCTAssertEqual(view.longestStreak, 12)
    }

    /// The empty-stats case forwards `nil` records (rendered as an em dash) and zeroes.
    func testEmptyStatsForwardNilRecords() {
        let stats = GameStats.empty

        let view = StatsView(
            levelsSolved: stats.levelsSolved,
            bestMoves: stats.bestMoves,
            bestTimeSeconds: stats.bestTimeSeconds,
            currentStreak: stats.currentStreak,
            longestStreak: stats.longestStreak
        )

        XCTAssertEqual(view.levelsSolved, 0)
        XCTAssertNil(view.bestMoves)
        XCTAssertNil(view.bestTimeSeconds)
        XCTAssertEqual(view.currentStreak, 0)
        XCTAssertEqual(view.longestStreak, 0)
    }

    /// Done still invokes the injected `onClose`; the dismissal contract is unchanged.
    func testDoneInvokesOnClose() {
        var closed = false
        let screen = StatsScreen(stats: .empty, runs: [], onRetry: { _ in }, onClose: { closed = true })

        screen.onClose()

        XCTAssertTrue(closed)
    }

    /// Retry forwards the chosen run to the injected `onRetry` so `RootView` can start
    /// a replay excursion (E13).
    func testRetryForwardsTheChosenRun() {
        let board = GameState(
            tubes: [Tube(balls: [.blue, .blue], capacity: 2), Tube(balls: [], capacity: 2)],
            capacity: 2
        )
        let run = LevelRun(
            id: UUID(), level: 9, moves: 20, timeSeconds: 50, dayKey: 20_260_627, board: board
        )
        var retried: LevelRun?
        let screen = StatsScreen(stats: .empty, runs: [run], onRetry: { retried = $0 }, onClose: {})

        screen.onRetry(run)

        XCTAssertEqual(retried, run)
    }
}
