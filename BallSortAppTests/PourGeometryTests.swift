import XCTest
import CoreGraphics
@testable import BallSortApp

/// Pure-math coverage for the pour-arc geometry (E14.3): launch/landing points and the
/// parabolic flight path. These pin the coordinate math so a tuning pass on device only
/// touches feel (peak height, duration), never correctness.
final class PourGeometryTests: XCTestCase {

    private let pad = BoardLayout.tubeVerticalPadding

    // A tube 100 wide at x∈[0,100], top at y=200, holding capacity-4 columns.
    private let tube = CGRect(x: 0, y: 200, width: 100, height: 400)

    func testMouthPointIsTopSlotCentreRegardlessOfFill() {
        let p = PourGeometry.mouthPoint(in: tube, ballSize: 50)
        XCTAssertEqual(p.x, 50, accuracy: 0.001)            // tube centre x
        XCTAssertEqual(p.y, 200 + pad + 25, accuracy: 0.001) // top + padding + ballSize/2
    }

    func testLandingPointForFirstBallSitsAtTheBottomSlot() {
        // capacity 4, one ball after the move -> rests in the bottom slot (index 3 from top).
        let p = PourGeometry.landingPoint(
            in: tube, capacity: 4, countAfterMove: 1, ballSize: 50, ballGap: 10
        )
        XCTAssertEqual(p.x, 50, accuracy: 0.001)
        XCTAssertEqual(p.y, 200 + pad + 3 * (50 + 10) + 25, accuracy: 0.001)
    }

    func testLandingPointRisesAsTheTubeFills() {
        // A fuller tube (3 balls) lands higher up than a near-empty one (1 ball).
        let low = PourGeometry.landingPoint(in: tube, capacity: 4, countAfterMove: 1, ballSize: 50, ballGap: 10)
        let high = PourGeometry.landingPoint(in: tube, capacity: 4, countAfterMove: 3, ballSize: 50, ballGap: 10)
        XCTAssertLessThan(high.y, low.y, "more balls -> the new top rests higher (smaller y)")
        // 3rd ball sits two slots above the bottom: index 1 from top.
        XCTAssertEqual(high.y, 200 + pad + 1 * (50 + 10) + 25, accuracy: 0.001)
    }

    func testArcStartsAtLaunchAndEndsAtLanding() {
        let launch = CGPoint(x: 10, y: 220)
        let land = CGPoint(x: 90, y: 360)
        XCTAssertEqual(PourGeometry.arcPoint(from: launch, to: land, peak: 80, progress: 0), launch)
        XCTAssertEqual(PourGeometry.arcPoint(from: launch, to: land, peak: 80, progress: 1), land)
    }

    func testArcLiftsAboveTheStraightLineAtMidpoint() {
        let launch = CGPoint(x: 0, y: 300)
        let land = CGPoint(x: 100, y: 300)
        let mid = PourGeometry.arcPoint(from: launch, to: land, peak: 80, progress: 0.5)
        XCTAssertEqual(mid.x, 50, accuracy: 0.001)           // halfway across
        XCTAssertEqual(mid.y, 300 - 80, accuracy: 0.001)     // full peak above the line (y grows downward)
    }

    func testArcClampsProgressOutsideUnitRange() {
        let launch = CGPoint(x: 0, y: 0)
        let land = CGPoint(x: 100, y: 0)
        XCTAssertEqual(PourGeometry.arcPoint(from: launch, to: land, peak: 50, progress: -1), launch)
        XCTAssertEqual(PourGeometry.arcPoint(from: launch, to: land, peak: 50, progress: 2), land)
    }
}
