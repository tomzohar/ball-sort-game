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

    // MARK: - No plateau (E14.1)

    /// A monotone proxy for how hard a level's parameters are: bigger board
    /// (`colors * capacity`) and a higher min-moves floor make it harder; more empty
    /// tubes make it easier. Every term moves difficulty the right way, so the proxy
    /// is non-decreasing exactly when the curve never eases off.
    private func difficultyPotential(_ p: LevelParameters) -> Int {
        p.colors * p.capacity + p.minMoves - p.emptyTubes
    }

    /// The bug this task fixes: the curve used to max out every parameter by ~level 9
    /// and then flatline, contradicting the brief's "infinite rising difficulty." Deep
    /// levels must be strictly harder than the old plateau point.
    func testCurveDoesNotPlateauAfterTheEarlyGame() {
        let curve = DifficultyCurve.default
        XCTAssertNotEqual(
            curve.parameters(forLevel: 20), curve.parameters(forLevel: 9),
            "level 20 must differ from level 9 — the curve plateaued"
        )
        XCTAssertGreaterThan(
            difficultyPotential(curve.parameters(forLevel: 20)),
            difficultyPotential(curve.parameters(forLevel: 9)),
            "level 20 must be strictly harder than level 9"
        )
    }

    /// Difficulty must never drop as the player advances, including across the points
    /// where empty tubes fall away and capacity steps up.
    func testDifficultyPotentialIsNonDecreasing() {
        let curve = DifficultyCurve.default
        var previous = Int.min
        for level in 1...40 {
            let potential = difficultyPotential(curve.parameters(forLevel: level))
            XCTAssertGreaterThanOrEqual(potential, previous, "difficulty dropped at level \(level)")
            previous = potential
        }
    }

    /// Capacity is the deep-game difficulty lever (it stays solver-feasible only while
    /// there is a single empty tube): a gentle start of 4, non-decreasing, climbing to
    /// the cap and never past it.
    func testCapacityGrowsNonDecreasingAndCapped() {
        let curve = DifficultyCurve.default
        XCTAssertEqual(curve.parameters(forLevel: 1).capacity, 4, "level 1 stays the gentle 4-ball tube")
        var previous = 0
        for level in 1...40 {
            let capacity = curve.parameters(forLevel: level).capacity
            XCTAssertGreaterThanOrEqual(capacity, previous, "capacity dropped at level \(level)")
            XCTAssertLessThanOrEqual(capacity, curve.maxCapacity)
            previous = capacity
        }
        XCTAssertEqual(
            curve.parameters(forLevel: 40).capacity, curve.maxCapacity,
            "capacity should reach its ceiling deep in the curve"
        )
    }

    /// Capacity must only grow once the curve has dropped to a single empty tube —
    /// growing it while two empties remain pushes the solver into 10s+ generation times.
    func testCapacityOnlyGrowsAfterEmptyTubesBottomOut() {
        let curve = DifficultyCurve.default
        for level in 1...40 {
            let p = curve.parameters(forLevel: level)
            if p.capacity > 4 {
                XCTAssertEqual(
                    p.emptyTubes, curve.minEmptyTubes,
                    "capacity grew to \(p.capacity) at level \(level) while \(p.emptyTubes) empty tubes remained"
                )
            }
        }
    }
}
