import CoreGraphics
import Testing
@testable import BallSortApp

/// Unit tests for the pure adaptive-sizing math in `BoardLayout`.
/// No SwiftUI / simulator required — this is plain arithmetic.
struct BoardLayoutTests {

    // MARK: - Formula at representative widths / tube counts

    @Test("narrow iPhone width clamps ball size below the cap")
    func narrowWidthClampsDown() {
        // 390 (iPhone 14/15 portrait), 8 tubes:
        // min(390-70, 620)=320; floor(320/8)=40; 40-10=30; min(58, 30)=30 -> below cap.
        let size = BoardLayout.ballSize(availableWidth: 390, tubeCount: 8)
        #expect(size == 30)
        #expect(size < BoardLayout.defaultMaxBall)
    }

    @Test("wide width caps at maxBall")
    func wideWidthCapsAtMax() {
        let size = BoardLayout.ballSize(availableWidth: 1200, tubeCount: 4)
        #expect(size == BoardLayout.defaultMaxBall)
    }

    @Test("the 620 row-width cap kicks in for very wide layouts")
    func rowWidthCapKicksIn() {
        // With width huge, usable is capped at 620. 12 tubes:
        // floor(620/12)=51; 51-10=41; min(58,41)=41
        let capped = BoardLayout.ballSize(availableWidth: 5000, tubeCount: 12)
        #expect(capped == 41)
        // Above the inflection point, growing width no longer changes the result.
        let evenWider = BoardLayout.ballSize(availableWidth: 9000, tubeCount: 12)
        #expect(evenWider == capped)
    }

    @Test("matches the prototype formula at a sample point")
    func matchesPrototypeFormula() {
        // width 690 -> 690-70=620 (the cap); 5 tubes: floor(620/5)=124; 124-10=114; min(58,114)=58
        #expect(BoardLayout.ballSize(availableWidth: 690, tubeCount: 5) == 58)
        // width 400, 6 tubes: min(330,620)=330; floor(330/6)=55; 55-10=45; min(58,45)=45
        #expect(BoardLayout.ballSize(availableWidth: 400, tubeCount: 6) == 45)
    }

    // MARK: - maxBall override (iPad larger cap)

    @Test("larger maxBall (iPad) yields a larger size when width allows")
    func iPadCapAllowsLargerBall() {
        let compact = BoardLayout.ballSize(availableWidth: 1100, tubeCount: 5, maxBall: 58)
        let regular = BoardLayout.ballSize(availableWidth: 1100, tubeCount: 5, maxBall: 80)
        #expect(compact == 58)
        // width 1100 -> usable 620; floor(620/5)=124; 124-10=114; min(80,114)=80
        #expect(regular == 80)
        #expect(regular > compact)
    }

    // MARK: - Monotonicity

    @Test("more tubes never increases ball size at fixed width")
    func moreTubesNeverLarger() {
        let width: CGFloat = 500
        var previous = CGFloat.greatestFiniteMagnitude
        for count in 1...20 {
            let size = BoardLayout.ballSize(availableWidth: width, tubeCount: count)
            #expect(size <= previous)
            previous = size
        }
    }

    @Test("wider width never decreases ball size (up to the cap)")
    func widerWidthNeverSmaller() {
        let count = 6
        var previous = CGFloat(0)
        for width in stride(from: CGFloat(120), through: 1400, by: 20) {
            let size = BoardLayout.ballSize(availableWidth: width, tubeCount: count)
            #expect(size >= previous)
            previous = size
        }
    }

    // MARK: - Robustness: never NaN / negative / below min

    @Test("tiny widths clamp to minBall, never below")
    func tinyWidthsClampToMin() {
        for width in stride(from: CGFloat(-100), through: 80, by: 10) {
            let size = BoardLayout.ballSize(availableWidth: width, tubeCount: 4)
            #expect(size >= BoardLayout.minBall)
            #expect(size.isFinite)
        }
    }

    @Test("large tube counts clamp to minBall")
    func largeTubeCountClampsToMin() {
        let size = BoardLayout.ballSize(availableWidth: 390, tubeCount: 1000)
        #expect(size == BoardLayout.minBall)
    }

    @Test("degenerate inputs (zero/negative tubeCount, NaN width, NaN cap) stay valid")
    func degenerateInputsStayValid() {
        #expect(BoardLayout.ballSize(availableWidth: 400, tubeCount: 0).isFinite)
        #expect(BoardLayout.ballSize(availableWidth: 400, tubeCount: 0) >= BoardLayout.minBall)
        #expect(BoardLayout.ballSize(availableWidth: 400, tubeCount: -5) >= BoardLayout.minBall)

        let nanWidth = BoardLayout.ballSize(availableWidth: .nan, tubeCount: 4)
        #expect(nanWidth.isFinite)
        #expect(nanWidth >= BoardLayout.minBall)

        let infWidth = BoardLayout.ballSize(availableWidth: .infinity, tubeCount: 4)
        #expect(infWidth.isFinite)
        #expect(infWidth <= BoardLayout.defaultMaxBall)

        let nanCap = BoardLayout.ballSize(availableWidth: 400, tubeCount: 4, maxBall: .nan)
        #expect(nanCap.isFinite)
        #expect(nanCap >= BoardLayout.minBall)
    }

    @Test("tubeCount 0 and 1 produce the same size (count floored to 1)")
    func zeroAndOneTubeCountMatch() {
        #expect(
            BoardLayout.ballSize(availableWidth: 400, tubeCount: 0)
                == BoardLayout.ballSize(availableWidth: 400, tubeCount: 1)
        )
    }

    // MARK: - Derived dimensions

    @Test("tubeWidth = ballSize + 2× horizontal padding")
    func tubeWidthDerivation() {
        let ball: CGFloat = 50
        let expected: CGFloat = 50 + 2 * 5  // ball + 2× horizontal padding (5) = 60
        #expect(BoardLayout.tubeWidth(ballSize: ball) == expected)
    }

    @Test("tubeHeight = capacity·ball + (capacity-1)·gap + 2× vertical padding")
    func tubeHeightDerivation() {
        // ball 50, capacity 4: 4*50 + 3*8 + 2*6 = 200 + 24 + 12 = 236
        #expect(BoardLayout.tubeHeight(ballSize: 50, capacity: 4) == 236)
    }

    @Test("tubeHeight with capacity 1 has no interior gaps")
    func tubeHeightSingleBall() {
        // ball 50, capacity 1: 50 + 0 + 12 = 62
        #expect(BoardLayout.tubeHeight(ballSize: 50, capacity: 1) == 62)
    }

    @Test("tubeHeight with capacity 0 is just padding")
    func tubeHeightEmpty() {
        #expect(BoardLayout.tubeHeight(ballSize: 50, capacity: 0) == 12)
        // Negative capacity treated as 0.
        #expect(BoardLayout.tubeHeight(ballSize: 50, capacity: -3) == 12)
    }
}
