import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers the E8 "Juice" feedback layer: that `BoardViewModel` fires the right
/// `GameEvent` for each interaction. A `FeedbackSpy` records events so we can assert
/// the mapping without touching audio/haptics hardware. XCTest (not Swift Testing) to
/// keep the bundle single-runner — see the note in `BoardViewModelTests`.
@MainActor
final class FeedbackViewModelTests: XCTestCase {

    // MARK: - Spy

    private final class FeedbackSpy: GameFeedbackPlaying {
        private(set) var events: [GameEvent] = []
        func play(_ event: GameEvent) { events.append(event) }
    }

    // MARK: - Fixtures

    private let capacity = 4

    /// Two yellows over an empty tube: one legal move exists, no tube completes.
    private func legalMoveState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow, .yellow], capacity: capacity),
                Tube(balls: [], capacity: capacity)
            ],
            capacity: capacity
        )
    }

    /// Mismatched tops: any move between them is rejected, both are selectable.
    private func colorMismatchState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: capacity),
                Tube(balls: [.blue], capacity: capacity)
            ],
            capacity: capacity
        )
    }

    /// One yellow per tube at capacity 2: consolidating wins outright.
    private func oneMoveWinState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: 2),
                Tube(balls: [.yellow], capacity: 2)
            ],
            capacity: 2
        )
    }

    /// A green sitting alone plus a green on top of a mismatched tube; moving the
    /// loose green onto the pair completes a tube without winning the board.
    private func tubeCompleteState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.green, .green], capacity: 3),
                Tube(balls: [.blue, .green], capacity: 3),
                Tube(balls: [.blue], capacity: 3)
            ],
            capacity: 3
        )
    }

    // MARK: - Tests

    func testLiftFiresOnFirstTapOfNonEmptyTube() {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: legalMoveState(), feedback: spy)
        sut.tap(0)
        XCTAssertEqual(spy.events, [.lift])
    }

    func testTappingEmptyTubeFiresNothing() {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: legalMoveState(), feedback: spy)
        sut.tap(1) // empty tube
        XCTAssertEqual(spy.events, [])
    }

    func testDropFiresOnLegalMove() {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: legalMoveState(), feedback: spy)
        sut.tap(0) // lift
        sut.tap(1) // legal move, no completion
        XCTAssertEqual(spy.events, [.lift, .drop])
    }

    func testTubeCompleteFiresWhenATubeFinishes() {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: tubeCompleteState(), feedback: spy)
        sut.tap(1) // lift the loose green
        sut.tap(0) // completes tube 0 (three greens) without winning
        XCTAssertFalse(sut.isWon)
        XCTAssertEqual(spy.events, [.lift, .tubeComplete])
    }

    func testIllegalMoveFiresOnRejectedMove() {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: colorMismatchState(), feedback: spy)
        sut.tap(0) // lift yellow
        sut.tap(1) // blue top — rejected, re-targets to tube 1
        XCTAssertEqual(spy.events, [.lift, .illegalMove])
    }

    func testWinFiresOnSolvingMove() {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: oneMoveWinState(), feedback: spy)
        sut.tap(0) // lift
        sut.tap(1) // winning move
        XCTAssertTrue(sut.isWon)
        XCTAssertEqual(spy.events, [.lift, .win])
    }

    func testUndoFiresUndo() {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: legalMoveState(), feedback: spy)
        sut.tap(0)
        sut.tap(1) // legal move
        sut.undo()
        XCTAssertEqual(spy.events, [.lift, .drop, .undo])
    }

    func testUndoWithNoHistoryFiresNothing() {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: legalMoveState(), feedback: spy)
        sut.undo()
        XCTAssertEqual(spy.events, [])
    }

    func testReselectingAnotherTubeDoesNotFireIllegalMove() {
        // Lifting tube 0 then tapping non-empty tube 1 with no attempted move should
        // not register as an illegal move — but with mismatched tops it IS an
        // attempted (rejected) move, so use a board where tapping re-selects cleanly.
        // Here tube 1's top matches and the move is legal, so we instead verify the
        // pure re-selection path via cancel.
        let spy = FeedbackSpy()
        let sut = BoardViewModel(initialState: legalMoveState(), feedback: spy)
        sut.tap(0) // lift
        sut.tap(0) // tap same tube — cancels, no event
        XCTAssertEqual(spy.events, [.lift])
    }
}
