import CoreGraphics
import XCTest
@testable import BallSortApp

/// Unit tests for the pure adaptive-sizing math in `BoardLayout`.
/// No SwiftUI / simulator required — this is plain arithmetic.
///
/// Uses XCTest (not Swift Testing) so the app test bundle has a single test
/// runner: mixing XCTest and Swift Testing in one bundle can make
/// `xcodebuild test` exit non-zero under CI's `pipefail` even when tests pass.
final class BoardLayoutTests: XCTestCase {

    // MARK: - Formula at representative widths / tube counts

    /// narrow iPhone width clamps ball size below the cap
    func testNarrowWidthClampsDown() {
        // 390 (iPhone 14/15 portrait), 8 tubes:
        // min(390-70, 620)=320; floor(320/8)=40; 40-10=30; min(58, 30)=30 -> below cap.
        let size = BoardLayout.ballSize(availableWidth: 390, tubeCount: 8)
        XCTAssertEqual(size, 30)
        XCTAssertLessThan(size, BoardLayout.defaultMaxBall)
    }

    /// wide width caps at maxBall
    func testWideWidthCapsAtMax() {
        let size = BoardLayout.ballSize(availableWidth: 1200, tubeCount: 4)
        XCTAssertEqual(size, BoardLayout.defaultMaxBall)
    }

    /// the 620 row-width cap kicks in for very wide layouts
    func testRowWidthCapKicksIn() {
        // With width huge, usable is capped at 620. 12 tubes:
        // floor(620/12)=51; 51-10=41; min(58,41)=41
        let capped = BoardLayout.ballSize(availableWidth: 5000, tubeCount: 12)
        XCTAssertEqual(capped, 41)
        // Above the inflection point, growing width no longer changes the result.
        let evenWider = BoardLayout.ballSize(availableWidth: 9000, tubeCount: 12)
        XCTAssertEqual(evenWider, capped)
    }

    /// matches the prototype formula at a sample point
    func testMatchesPrototypeFormula() {
        // width 690 -> 690-70=620 (the cap); 5 tubes: floor(620/5)=124; 124-10=114; min(58,114)=58
        XCTAssertEqual(BoardLayout.ballSize(availableWidth: 690, tubeCount: 5), 58)
        // width 400, 6 tubes: min(330,620)=330; floor(330/6)=55; 55-10=45; min(58,45)=45
        XCTAssertEqual(BoardLayout.ballSize(availableWidth: 400, tubeCount: 6), 45)
    }

    // MARK: - maxBall override (iPad larger cap)

    /// larger maxBall (iPad) yields a larger size when width allows
    func testIPadCapAllowsLargerBall() {
        let compact = BoardLayout.ballSize(availableWidth: 1100, tubeCount: 5, maxBall: 58)
        let regular = BoardLayout.ballSize(availableWidth: 1100, tubeCount: 5, maxBall: 80)
        XCTAssertEqual(compact, 58)
        // width 1100 -> usable 620; floor(620/5)=124; 124-10=114; min(80,114)=80
        XCTAssertEqual(regular, 80)
        XCTAssertGreaterThan(regular, compact)
    }

    // MARK: - Monotonicity

    /// more tubes never increases ball size at fixed width
    func testMoreTubesNeverLarger() {
        let width: CGFloat = 500
        var previous = CGFloat.greatestFiniteMagnitude
        for count in 1...20 {
            let size = BoardLayout.ballSize(availableWidth: width, tubeCount: count)
            XCTAssertLessThanOrEqual(size, previous)
            previous = size
        }
    }

    /// wider width never decreases ball size (up to the cap)
    func testWiderWidthNeverSmaller() {
        let count = 6
        var previous = CGFloat(0)
        for width in stride(from: CGFloat(120), through: 1400, by: 20) {
            let size = BoardLayout.ballSize(availableWidth: width, tubeCount: count)
            XCTAssertGreaterThanOrEqual(size, previous)
            previous = size
        }
    }

    // MARK: - Robustness: never NaN / negative / below min

    /// tiny widths clamp to minBall, never below
    func testTinyWidthsClampToMin() {
        for width in stride(from: CGFloat(-100), through: 80, by: 10) {
            let size = BoardLayout.ballSize(availableWidth: width, tubeCount: 4)
            XCTAssertGreaterThanOrEqual(size, BoardLayout.minBall)
            XCTAssertTrue(size.isFinite)
        }
    }

    /// large tube counts clamp to minBall
    func testLargeTubeCountClampsToMin() {
        let size = BoardLayout.ballSize(availableWidth: 390, tubeCount: 1000)
        XCTAssertEqual(size, BoardLayout.minBall)
    }

    /// degenerate inputs (zero/negative tubeCount, NaN width, NaN cap) stay valid
    func testDegenerateInputsStayValid() {
        XCTAssertTrue(BoardLayout.ballSize(availableWidth: 400, tubeCount: 0).isFinite)
        XCTAssertGreaterThanOrEqual(BoardLayout.ballSize(availableWidth: 400, tubeCount: 0), BoardLayout.minBall)
        XCTAssertGreaterThanOrEqual(BoardLayout.ballSize(availableWidth: 400, tubeCount: -5), BoardLayout.minBall)

        let nanWidth = BoardLayout.ballSize(availableWidth: .nan, tubeCount: 4)
        XCTAssertTrue(nanWidth.isFinite)
        XCTAssertGreaterThanOrEqual(nanWidth, BoardLayout.minBall)

        let infWidth = BoardLayout.ballSize(availableWidth: .infinity, tubeCount: 4)
        XCTAssertTrue(infWidth.isFinite)
        XCTAssertLessThanOrEqual(infWidth, BoardLayout.defaultMaxBall)

        let nanCap = BoardLayout.ballSize(availableWidth: 400, tubeCount: 4, maxBall: .nan)
        XCTAssertTrue(nanCap.isFinite)
        XCTAssertGreaterThanOrEqual(nanCap, BoardLayout.minBall)
    }

    /// tubeCount 0 and 1 produce the same size (count floored to 1)
    func testZeroAndOneTubeCountMatch() {
        XCTAssertEqual(
            BoardLayout.ballSize(availableWidth: 400, tubeCount: 0),
            BoardLayout.ballSize(availableWidth: 400, tubeCount: 1)
        )
    }

    // MARK: - Derived dimensions

    /// tubeWidth = ballSize + 2× horizontal padding
    func testTubeWidthDerivation() {
        let ball: CGFloat = 50
        let expected: CGFloat = 50 + 2 * 5  // ball + 2× horizontal padding (5) = 60
        XCTAssertEqual(BoardLayout.tubeWidth(ballSize: ball), expected)
    }

    /// tubeHeight = capacity·ball + (capacity-1)·gap + 2× vertical padding
    func testTubeHeightDerivation() {
        // ball 50, capacity 4: 4*50 + 3*8 + 2*6 = 200 + 24 + 12 = 236
        XCTAssertEqual(BoardLayout.tubeHeight(ballSize: 50, capacity: 4), 236)
    }

    /// tubeHeight with capacity 1 has no interior gaps
    func testTubeHeightSingleBall() {
        // ball 50, capacity 1: 50 + 0 + 12 = 62
        XCTAssertEqual(BoardLayout.tubeHeight(ballSize: 50, capacity: 1), 62)
    }

    /// tubeHeight with capacity 0 is just padding
    func testTubeHeightEmpty() {
        XCTAssertEqual(BoardLayout.tubeHeight(ballSize: 50, capacity: 0), 12)
        // Negative capacity treated as 0.
        XCTAssertEqual(BoardLayout.tubeHeight(ballSize: 50, capacity: -3), 12)
    }

    // MARK: - Fitted ball size (single row, fills width AND height)

    /// Binds on height when the area is short and wide.
    func testFittedBindsOnHeight() {
        // 4 tubes, capacity 4, generous width, short height 300:
        // heightFit = (300 - 12 - 3*8)/4 = (300-36)/4 = 66.
        let size = BoardLayout.fittedBallSize(
            available: CGSize(width: 4000, height: 300),
            tubeCount: 4, capacity: 4, maxBall: 200
        )
        XCTAssertEqual(size, 66)
    }

    /// Binds on width when the area is tall and narrow.
    func testFittedBindsOnWidth() {
        // 4 tubes, capacity 4, width 300, tall height:
        // rowWidth = 300 - 8*3 = 276; widthFit = 276/4 - 10 = 69 - 10 = 59.
        let size = BoardLayout.fittedBallSize(
            available: CGSize(width: 300, height: 4000),
            tubeCount: 4, capacity: 4, maxBall: 200
        )
        XCTAssertEqual(size, 59)
    }

    /// More tubes in the single row shrink the width-bound ball size.
    func testFittedMoreTubesShrinkWidth() {
        // 7 tubes, width 390, tall height: rowWidth = 390 - 8*6 = 342;
        // widthFit = 342/7 - 10 = 48.857… -> floor(38.857) = 38.
        let size = BoardLayout.fittedBallSize(
            available: CGSize(width: 390, height: 4000),
            tubeCount: 7, capacity: 4, maxBall: 200
        )
        XCTAssertEqual(size, 38)
    }

    /// Clamps to maxBall when both dimensions are huge.
    func testFittedClampsToMax() {
        let size = BoardLayout.fittedBallSize(
            available: CGSize(width: 9000, height: 9000),
            tubeCount: 3, capacity: 4, maxBall: 120
        )
        XCTAssertEqual(size, 120)
    }

    /// Degenerate inputs stay finite and never below minBall.
    func testFittedRobustness() {
        for w in [CGFloat(-100), 0, .nan, .infinity] {
            for h in [CGFloat(-100), 0, .nan, .infinity] {
                let size = BoardLayout.fittedBallSize(
                    available: CGSize(width: w, height: h),
                    tubeCount: 6, capacity: 4, maxBall: 120
                )
                XCTAssertTrue(size.isFinite)
                XCTAssertGreaterThanOrEqual(size, BoardLayout.minBall)
            }
        }
    }
}
