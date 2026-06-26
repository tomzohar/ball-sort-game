import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers the `DifficultyCurve` formula: it must rise monotonically with level so
/// the game never gets easier as the player advances (E5.5).
final class DifficultyCurveTests: XCTestCase {

    func testLevelOneIsTheGentleStart() {
        let params = DifficultyCurve.default.parameters(forLevel: 1)
        XCTAssertEqual(params, LevelParameters(colors: 4, capacity: 4, emptyTubes: 2, minMoves: 10))
    }

    func testLevelClampsBelowOne() {
        let curve = DifficultyCurve.default
        XCTAssertEqual(curve.parameters(forLevel: 0), curve.parameters(forLevel: 1))
        XCTAssertEqual(curve.parameters(forLevel: -5), curve.parameters(forLevel: 1))
    }

    func testMinMovesFloorIsNonDecreasingAndCapped() {
        let curve = DifficultyCurve.default
        var previous = 0
        for level in 1...40 {
            let minMoves = curve.parameters(forLevel: level).minMoves
            XCTAssertGreaterThanOrEqual(minMoves, previous, "min-moves dropped at level \(level)")
            XCTAssertLessThanOrEqual(minMoves, curve.maxMinMoves)
            previous = minMoves
        }
        // The floor actually rises over the early game (lever is not flat).
        XCTAssertGreaterThan(
            curve.parameters(forLevel: 5).minMoves,
            curve.parameters(forLevel: 1).minMoves
        )
    }

    func testColorsAreNonDecreasingAndCapped() {
        let curve = DifficultyCurve.default
        var previous = 0
        for level in 1...50 {
            let colors = curve.parameters(forLevel: level).colors
            XCTAssertGreaterThanOrEqual(colors, previous)
            XCTAssertLessThanOrEqual(colors, curve.maxColors)
            previous = colors
        }
    }

    func testEmptyTubesAreNonIncreasingAndFloored() {
        let curve = DifficultyCurve.default
        var previous = Int.max
        for level in 1...50 {
            let empties = curve.parameters(forLevel: level).emptyTubes
            XCTAssertLessThanOrEqual(empties, previous, "empty tubes rose at level \(level)")
            XCTAssertGreaterThanOrEqual(empties, curve.minEmptyTubes)
            previous = empties
        }
    }

    func testEstimatedBandIsNonDecreasing() {
        let curve = DifficultyCurve.default
        var previous = Difficulty.Band.trivial
        for level in 1...20 {
            let band = curve.estimatedBand(forLevel: level)
            XCTAssertGreaterThanOrEqual(band, previous)
            previous = band
        }
    }
}
