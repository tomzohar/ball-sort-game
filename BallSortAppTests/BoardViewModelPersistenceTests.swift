import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers the E7 persistence wiring in `BoardViewModel`: snapshotting the
/// in-progress level after each mutation, recording wins into `StatsStore`, and
/// restoring a `SavedGame` on construction. XCTest (not Swift Testing) to keep the
/// app test bundle single-runner — see `BoardViewModelTests`.
@MainActor
final class BoardViewModelPersistenceTests: XCTestCase {

    private let capacity = 2

    /// A board one legal move from a win: move tube 0's ball onto tube 1.
    private func nearWinState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: capacity),
                Tube(balls: [.yellow], capacity: capacity)
            ],
            capacity: capacity
        )
    }

    private func loadSavedGame(_ store: some PersistenceStore) -> SavedGame? {
        guard let saved = try? store.load(SavedGame.self, forKey: PersistenceKeys.savedGame) else {
            return nil
        }
        return saved
    }

    // MARK: - Persisting the in-progress level

    func testMovePersistsSavedGame() {
        let store = InMemoryPersistenceStore()
        let sut = BoardViewModel(initialState: nearWinState(), persistence: store)

        sut.tap(0) // lift
        sut.tap(1) // drop — one move applied

        let saved = loadSavedGame(store)
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.moveCount, 1)
        XCTAssertEqual(saved?.gameState, sut.gameState)
        XCTAssertEqual(saved?.level, sut.level)
    }

    func testNoSavedGameBeforeFirstMutation() {
        let store = InMemoryPersistenceStore()
        _ = BoardViewModel(initialState: nearWinState(), persistence: store)

        XCTAssertNil(loadSavedGame(store))
    }

    func testRestartPersistsResetBoard() {
        let store = InMemoryPersistenceStore()
        let sut = BoardViewModel(initialState: nearWinState(), persistence: store)
        sut.tap(0); sut.tap(1)

        sut.restart()

        let saved = loadSavedGame(store)
        XCTAssertEqual(saved?.moveCount, 0)
        XCTAssertEqual(saved?.gameState, sut.gameState)
    }

    // MARK: - Recording wins

    func testWinRecordsStats() {
        let statsStore = StatsStore(persistence: InMemoryPersistenceStore(), today: { 20_260_627 })
        let sut = BoardViewModel(
            initialState: nearWinState(),
            persistence: InMemoryPersistenceStore(),
            statsStore: statsStore
        )

        sut.tap(0) // lift
        sut.tap(1) // drop — wins

        XCTAssertTrue(sut.isWon)
        XCTAssertEqual(statsStore.stats.levelsSolved, 1)
        XCTAssertEqual(statsStore.stats.bestMoves, 1)
    }

    func testWinRecordsHistoryWithStartingBoard() {
        let historyStore = HistoryStore(
            persistence: InMemoryPersistenceStore(),
            today: { 20_260_627 }
        )
        let start = nearWinState()
        let sut = BoardViewModel(
            initialState: start,
            persistence: InMemoryPersistenceStore(),
            historyStore: historyStore
        )

        sut.tap(0) // lift
        sut.tap(1) // drop — wins

        XCTAssertTrue(sut.isWon)
        XCTAssertEqual(historyStore.history.runs.count, 1)
        let run = historyStore.history.runs[0]
        XCTAssertEqual(run.level, 1)
        XCTAssertEqual(run.moves, 1)
        // The run captures the level's STARTING board (for replay), not the won one.
        XCTAssertEqual(run.board, start)
    }

    // MARK: - Restoring

    func testRestoreInstallsSavedBoard() {
        let saved = SavedGame(
            level: 4,
            gameState: nearWinState(),
            initialState: nearWinState(),
            moveCount: 7,
            elapsedSeconds: 42
        )
        let sut = BoardViewModel(restoring: saved, now: { 1000 })

        XCTAssertFalse(sut.isGenerating)
        XCTAssertEqual(sut.level, 4)
        XCTAssertEqual(sut.moveCount, 7)
        XCTAssertEqual(sut.gameState, saved.gameState)
        XCTAssertEqual(sut.elapsed, 42, accuracy: 0.001)
    }
}
