import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers `HistoryStore` (E13): recording wins as replayable runs, persisting them
/// through the injected store, and reloading them on construction. The "today"
/// day-key and the run `id` factory are injected so recording is deterministic.
/// XCTest (not Swift Testing) to keep the app test bundle single-runner.
@MainActor
final class HistoryStoreTests: XCTestCase {

    private func board(_ color: BallColor = .blue) -> GameState {
        GameState(
            tubes: [Tube(balls: [color, color], capacity: 2), Tube(balls: [], capacity: 2)],
            capacity: 2
        )
    }

    private func id(_ value: Int) -> UUID {
        UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", value))")!
    }

    func testStartsEmptyWhenNothingPersisted() {
        let sut = HistoryStore(persistence: InMemoryPersistenceStore())
        XCTAssertTrue(sut.history.runs.isEmpty)
    }

    func testRecordCapturesTheRunWithItsBoard() {
        let sut = HistoryStore(
            persistence: InMemoryPersistenceStore(),
            today: { 20_260_627 },
            makeID: { self.id(1) }
        )

        sut.record(level: 5, board: board(.pink), moves: 14, seconds: 33)

        XCTAssertEqual(sut.history.runs.count, 1)
        let run = sut.history.runs[0]
        XCTAssertEqual(run.level, 5)
        XCTAssertEqual(run.moves, 14)
        XCTAssertEqual(run.timeSeconds, 33)
        XCTAssertEqual(run.dayKey, 20_260_627)
        XCTAssertEqual(run.board, board(.pink))
        XCTAssertEqual(run.id, id(1))
    }

    func testRecordsAreNewestFirst() {
        var counter = 0
        let sut = HistoryStore(
            persistence: InMemoryPersistenceStore(),
            today: { 20_260_627 },
            makeID: { counter += 1; return self.id(counter) }
        )

        sut.record(level: 1, board: board(), moves: 5, seconds: 10)
        sut.record(level: 2, board: board(), moves: 6, seconds: 11)

        XCTAssertEqual(sut.history.runs.map(\.level), [2, 1])
    }

    func testRecordPersistsAcrossInstances() {
        let store = InMemoryPersistenceStore()
        let first = HistoryStore(persistence: store, today: { 20_260_627 }, makeID: { self.id(7) })
        first.record(level: 3, board: board(.green), moves: 8, seconds: 20)

        let reloaded = HistoryStore(persistence: store)

        XCTAssertEqual(reloaded.history.runs.count, 1)
        XCTAssertEqual(reloaded.history.runs[0].level, 3)
        XCTAssertEqual(reloaded.history.runs[0].board, board(.green))
    }
}
