import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers the E13 replay excursion in `BoardViewModel`: entering a replay installs a
/// past level's exact board without disturbing the saved current level, a replay win
/// sharpens records but doesn't advance progression, and `exitReplay()` restores the
/// stashed level. XCTest to keep the app test bundle single-runner.
@MainActor
final class BoardViewModelReplayTests: XCTestCase {

    private let capacity = 2

    /// A current-level board with a legal, non-winning move (t0 top → empty t2).
    private func currentBoard() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow, .blue], capacity: capacity),
                Tube(balls: [.blue, .yellow], capacity: capacity),
                Tube(balls: [], capacity: capacity)
            ],
            capacity: capacity
        )
    }

    /// A near-win board: t0's ball onto t1 completes it.
    private func replayBoard() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: capacity),
                Tube(balls: [.yellow], capacity: capacity),
                Tube(balls: [], capacity: capacity)
            ],
            capacity: capacity
        )
    }

    private func run(level: Int, board: GameState) -> LevelRun {
        LevelRun(id: UUID(), level: level, moves: 9, timeSeconds: 30, dayKey: 20_260_627, board: board)
    }

    private func loadSavedGame(_ store: some PersistenceStore) -> SavedGame? {
        guard let saved = try? store.load(SavedGame.self, forKey: PersistenceKeys.savedGame) else {
            return nil
        }
        return saved
    }

    // MARK: - Entering a replay

    func testReplayInstallsTheRunBoardAndEntersReplayMode() {
        let sut = BoardViewModel(initialState: currentBoard())

        sut.replay(run(level: 5, board: replayBoard()))

        XCTAssertTrue(sut.isReplaying)
        XCTAssertEqual(sut.level, 5)
        XCTAssertEqual(sut.gameState, replayBoard())
        XCTAssertEqual(sut.moveCount, 0)
    }

    func testReplayDoesNotOverwriteTheSavedCurrentLevel() {
        let store = InMemoryPersistenceStore()
        let sut = BoardViewModel(initialState: currentBoard(), persistence: store)

        sut.tap(0); sut.tap(2) // one real move on the current level → persisted
        let savedBefore = loadSavedGame(store)
        XCTAssertEqual(savedBefore?.level, 1)
        XCTAssertEqual(savedBefore?.moveCount, 1)

        sut.replay(run(level: 5, board: replayBoard()))
        sut.tap(0); sut.tap(1) // a move during the replay

        // The saved current level is untouched by the excursion.
        let savedAfter = loadSavedGame(store)
        XCTAssertEqual(savedAfter, savedBefore)
    }

    // MARK: - Replay win

    func testReplayWinSharpensRecordsButDoesNotAdvanceProgression() {
        let stats = StatsStore(persistence: InMemoryPersistenceStore(), today: { 20_260_627 })
        let history = HistoryStore(persistence: InMemoryPersistenceStore(), today: { 20_260_627 })
        let sut = BoardViewModel(
            initialState: currentBoard(),
            persistence: InMemoryPersistenceStore(),
            statsStore: stats,
            historyStore: history
        )

        sut.replay(run(level: 5, board: replayBoard()))
        sut.tap(0); sut.tap(1) // wins the replay in one move

        XCTAssertTrue(sut.isWon)
        // Practice: solved count and streak stay put...
        XCTAssertEqual(stats.stats.levelsSolved, 0)
        XCTAssertEqual(stats.stats.currentStreak, 0)
        // ...but the record is sharpened and the run is logged.
        XCTAssertEqual(stats.stats.bestMoves, 1)
        XCTAssertEqual(history.history.runs.count, 1)
        XCTAssertEqual(history.history.runs[0].level, 5)
    }

    // MARK: - Exiting a replay

    func testExitReplayRestoresTheStashedCurrentLevel() {
        let sut = BoardViewModel(initialState: currentBoard())
        sut.tap(0); sut.tap(2) // current level: one move applied
        let levelBefore = sut.level
        let boardBefore = sut.gameState

        sut.replay(run(level: 5, board: replayBoard()))
        sut.exitReplay()

        XCTAssertFalse(sut.isReplaying)
        XCTAssertEqual(sut.level, levelBefore)
        XCTAssertEqual(sut.gameState, boardBefore)
        XCTAssertEqual(sut.moveCount, 1)
    }

    func testExitReplayIsNoOpWhenNotReplaying() {
        let sut = BoardViewModel(initialState: currentBoard())
        let board = sut.gameState

        sut.exitReplay()

        XCTAssertFalse(sut.isReplaying)
        XCTAssertEqual(sut.gameState, board)
    }
}
