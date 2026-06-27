import XCTest
@testable import BallSortApp

/// Round-trip contract for the on-disk `JSONFileStore`. Each test points the
/// store at a unique temp directory (cleaned up in `tearDown`) so the suite
/// never touches the real Application Support location and runs hermetically.
/// The save → load → remove cycle here is the e2e proof that the persistence
/// seam survives a real write/read.
///
/// XCTest (not Swift Testing): mixing both frameworks in one app test bundle
/// double-launches the runner; the rest of the bundle is XCTest, so we match.
final class JSONFileStoreTests: XCTestCase {

    /// A small Codable payload to round-trip.
    private struct Sample: Codable, Equatable {
        var level: Int
        var name: String
    }

    private var tempDir: URL!
    private var store: JSONFileStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("JSONFileStoreTests-\(UUID().uuidString)", isDirectory: true)
        store = JSONFileStore(baseDirectory: tempDir)
    }

    override func tearDownWithError() throws {
        if let tempDir, FileManager.default.fileExists(atPath: tempDir.path) {
            try FileManager.default.removeItem(at: tempDir)
        }
        tempDir = nil
        store = nil
        try super.tearDownWithError()
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

    func testEmptyKeyThrows() {
        XCTAssertThrowsError(try store.save(Sample(level: 0, name: ""), forKey: "   "))
    }
}
