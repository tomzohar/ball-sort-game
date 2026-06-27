import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers `StatsStore` (E7.2/E7.3): recording wins into durable stats, persisting
/// them through the injected store, and reloading them on construction. The
/// "today" day-key is injected so streak behavior is deterministic. XCTest (not
/// Swift Testing) to keep the app test bundle single-runner — see `BoardViewModelTests`.
@MainActor
final class StatsStoreTests: XCTestCase {

    func testStartsEmptyWhenNothingPersisted() {
        let sut = StatsStore(persistence: InMemoryPersistenceStore(), today: { 20_260_627 })
        XCTAssertEqual(sut.stats, .empty)
    }

    func testRecordWinUpdatesStats() {
        let sut = StatsStore(persistence: InMemoryPersistenceStore(), today: { 20_260_627 })

        sut.recordWin(moves: 12, seconds: 30)

        XCTAssertEqual(sut.stats.levelsSolved, 1)
        XCTAssertEqual(sut.stats.bestMoves, 12)
        XCTAssertEqual(sut.stats.bestTimeSeconds, 30)
        XCTAssertEqual(sut.stats.currentStreak, 1)
        XCTAssertEqual(sut.stats.longestStreak, 1)
    }

    func testRecordWinPersistsAcrossInstances() {
        let store = InMemoryPersistenceStore()
        let first = StatsStore(persistence: store, today: { 20_260_627 })
        first.recordWin(moves: 9, seconds: 45)

        // A fresh store reading the same backing should see the persisted stats.
        let reloaded = StatsStore(persistence: store, today: { 20_260_627 })

        XCTAssertEqual(reloaded.stats.levelsSolved, 1)
        XCTAssertEqual(reloaded.stats.bestMoves, 9)
        XCTAssertEqual(reloaded.stats.bestTimeSeconds, 45)
    }

    func testStreakIncrementsOnConsecutiveDays() {
        var day = 20_260_627
        let sut = StatsStore(persistence: InMemoryPersistenceStore(), today: { day })

        sut.recordWin(moves: 10, seconds: 20)
        day = 20_260_628
        sut.recordWin(moves: 10, seconds: 20)

        XCTAssertEqual(sut.stats.currentStreak, 2)
        XCTAssertEqual(sut.stats.longestStreak, 2)
        XCTAssertEqual(sut.stats.levelsSolved, 2)
    }

    func testStreakResetsAfterGap() {
        var day = 20_260_627
        let sut = StatsStore(persistence: InMemoryPersistenceStore(), today: { day })

        sut.recordWin(moves: 10, seconds: 20)
        day = 20_260_630 // three-day gap
        sut.recordWin(moves: 10, seconds: 20)

        XCTAssertEqual(sut.stats.currentStreak, 1)
        XCTAssertEqual(sut.stats.longestStreak, 1)
    }
}
