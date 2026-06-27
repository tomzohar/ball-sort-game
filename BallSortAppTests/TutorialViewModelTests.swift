import XCTest
@testable import BallSortApp

/// Covers `TutorialViewModel` step progression (E14.2): advancing, skipping, and
/// stepping back, plus the terminal `isFinished` contract the overlay relies on to
/// record that the tutorial was seen.
final class TutorialViewModelTests: XCTestCase {

    /// Three lightweight steps so the tests don't depend on the production copy.
    private func makeSteps(_ n: Int = 3) -> [TutorialStep] {
        (0..<n).map { TutorialStep(id: $0, symbol: "circle", title: "T\($0)", message: "M\($0)") }
    }

    func testStartsOnFirstStepNotFinished() {
        let sut = TutorialViewModel(steps: makeSteps())
        XCTAssertEqual(sut.index, 0)
        XCTAssertTrue(sut.isFirstStep)
        XCTAssertFalse(sut.isLastStep)
        XCTAssertFalse(sut.isFinished)
        XCTAssertEqual(sut.stepNumber, 1)
        XCTAssertEqual(sut.stepCount, 3)
    }

    func testAdvanceWalksThroughEveryStep() {
        let sut = TutorialViewModel(steps: makeSteps())
        sut.advance()
        XCTAssertEqual(sut.index, 1)
        XCTAssertFalse(sut.isFirstStep)
        XCTAssertFalse(sut.isLastStep)
        XCTAssertFalse(sut.isFinished)
        sut.advance()
        XCTAssertEqual(sut.index, 2)
        XCTAssertTrue(sut.isLastStep)
        XCTAssertFalse(sut.isFinished)
    }

    func testAdvanceOnLastStepFinishes() {
        let sut = TutorialViewModel(steps: makeSteps())
        sut.advance(); sut.advance() // now on last
        sut.advance()                // finish
        XCTAssertTrue(sut.isFinished)
        XCTAssertEqual(sut.index, 2, "finishing should not push the index past the last step")
    }

    func testAdvanceAfterFinishIsInert() {
        let sut = TutorialViewModel(steps: makeSteps(1))
        sut.advance() // single step -> finishes immediately
        XCTAssertTrue(sut.isFinished)
        sut.advance()
        XCTAssertTrue(sut.isFinished)
        XCTAssertEqual(sut.index, 0)
    }

    func testSkipFinishesFromAnyStep() {
        let sut = TutorialViewModel(steps: makeSteps())
        sut.advance() // middle step
        sut.skip()
        XCTAssertTrue(sut.isFinished)
        XCTAssertEqual(sut.index, 1, "skip records completion without changing the visible step")
    }

    func testBackStepsTowardStartButNotBelowZero() {
        let sut = TutorialViewModel(steps: makeSteps())
        sut.advance(); sut.advance()
        sut.back()
        XCTAssertEqual(sut.index, 1)
        sut.back()
        XCTAssertEqual(sut.index, 0)
        sut.back()
        XCTAssertEqual(sut.index, 0, "back on the first step is a no-op")
    }

    func testProductionStepsAreTheThreeBeatWalkthrough() {
        let sut = TutorialViewModel()
        XCTAssertEqual(sut.stepCount, 3, "default tutorial is the short three-beat walkthrough")
        XCTAssertFalse(sut.isFinished)
    }
}
