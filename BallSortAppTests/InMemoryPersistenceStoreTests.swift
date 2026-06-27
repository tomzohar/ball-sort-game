import XCTest
@testable import BallSortApp

/// The same behavioral contract as `JSONFileStoreTests`, run against the
/// in-memory fake to confirm it is a faithful stand-in for tests and previews.
///
/// XCTest (not Swift Testing) to keep the app test bundle single-runner.
final class InMemoryPersistenceStoreTests: XCTestCase {

    private struct Sample: Codable, Equatable {
        var level: Int
        var name: String
    }

    private var store: InMemoryPersistenceStore!

    override func setUp() {
        super.setUp()
        store = InMemoryPersistenceStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    func testSaveLoadRoundTripReturnsEqualValue() throws {
        let value = Sample(level: 7, name: "seven")
        try store.save(value, forKey: "progress")

        let loaded = try store.load(Sample.self, forKey: "progress")
        XCTAssertEqual(loaded, value)
    }

    func testLoadMissingKeyReturnsNil() throws {
        let loaded = try store.load(Sample.self, forKey: "absent")
        XCTAssertNil(loaded)
    }

    func testOverwriteReturnsLatestValue() throws {
        try store.save(Sample(level: 1, name: "one"), forKey: "progress")
        try store.save(Sample(level: 2, name: "two"), forKey: "progress")

        let loaded = try store.load(Sample.self, forKey: "progress")
        XCTAssertEqual(loaded, Sample(level: 2, name: "two"))
    }

    func testRemoveThenLoadReturnsNil() throws {
        try store.save(Sample(level: 9, name: "nine"), forKey: "progress")
        try store.remove(forKey: "progress")

        let loaded = try store.load(Sample.self, forKey: "progress")
        XCTAssertNil(loaded)
    }

    func testRemoveMissingKeyIsNoOp() throws {
        XCTAssertNoThrow(try store.remove(forKey: "absent"))
    }
}
