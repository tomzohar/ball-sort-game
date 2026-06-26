import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers the `DifficultyCurve` formula: it must rise monotonically with level so
/// the game never gets easier as the player advances (E5.5).
final class DifficultyCurveTests: XCTestCase {

    func testLevelOneMatchesShippedDefaults() {
        let params = DifficultyCurve.default.parameters(forLevel: 1)
        XCTAssertEqual(params, LevelParameters(colors: 5, capacity: 4, emptyTubes: 2, scrambleDepth: 80))
    }

    func testLevelClampsBelowOne() {
        let curve = DifficultyCurve.default
        XCTAssertEqual(curve.parameters(forLevel: 0), curve.parameters(forLevel: 1))
        XCTAssertEqual(curve.parameters(forLevel: -5), curve.parameters(forLevel: 1))
    }

    func testScrambleDepthStrictlyIncreases() {
        let curve = DifficultyCurve.default
        for level in 1..<30 {
            let here = curve.parameters(forLevel: level).scrambleDepth
            let next = curve.parameters(forLevel: level + 1).scrambleDepth
            XCTAssertGreaterThan(next, here, "scramble must strictly rise at level \(level)")
        }
    }

    func testColorsAreNonDecreasingAndCapped() {
        let curve = DifficultyCurve.default
        var previous = 0
        for level in 1...50 {
            let colors = curve.parameters(forLevel: level).colors
            XCTAssertGreaterThanOrEqual(colors, previous)
            XCTAssertLessThanOrEqual(colors, BallColor.allCases.count)
            previous = colors
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
