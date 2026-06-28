import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers the E6 hint additions to `BoardViewModel`: requesting the solver's
/// next-best move, exposing it as a highlightable `hintMove`, and clearing it on
/// any board mutation. The solve runs off the main actor (like grading), so tests
/// await `hintTask`. XCTest (not Swift Testing) to keep the bundle single-runner —
/// see the note in `BoardViewModelTests`.
@MainActor
final class HintViewModelTests: XCTestCase {

    // MARK: - Fakes & fixtures

    /// Returns a fixed sequence so the wiring (hint == solver's first move) is
    /// deterministic and solver-independent.
    private struct FakeSolver: Solving {
        let first: Move?
        func solve(_ state: GameState) -> [Move]? {
            guard let first else { return nil }
            return [first, Move(from: 1, to: 0)]
        }
    }

    /// Records the feedback events fired, so we can assert the hint cue (E14.7).
    private final class FeedbackSpy: GameFeedbackPlaying {
        private(set) var events: [GameEvent] = []
        func play(_ event: GameEvent) { events.append(event) }
    }

    /// A solvable, not-won 2-color board (4 tubes, capacity 2).
    private func solvableState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow, .blue], capacity: 2),
                Tube(balls: [.yellow, .blue], capacity: 2),
                Tube(balls: [], capacity: 2),
                Tube(balls: [], capacity: 2)
            ],
            capacity: 2
        )
    }

    /// An already-won board: every tube empty or a finished single-color stack.
    private func wonState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow, .yellow], capacity: 2),
                Tube(balls: [], capacity: 2)
            ],
            capacity: 2
        )
    }

    // MARK: - requestHint

    func testRequestHintExposesSolverFirstMove() async {
        let hint = Move(from: 0, to: 2)
        let sut = BoardViewModel(initialState: solvableState(), solver: FakeSolver(first: hint))

        sut.requestHint()
        await sut.hintTask?.value

        XCTAssertEqual(sut.hintMove, hint)
        XCTAssertFalse(sut.isHinting)
    }

    func testHintSourceAndTargetReflectHintMove() async {
        let sut = BoardViewModel(initialState: solvableState(), solver: FakeSolver(first: Move(from: 0, to: 2)))

        sut.requestHint()
        await sut.hintTask?.value

        XCTAssertTrue(sut.isHintSource(0))
        XCTAssertFalse(sut.isHintSource(2))
        XCTAssertTrue(sut.isHintTarget(2))
        XCTAssertFalse(sut.isHintTarget(0))
    }

    func testRequestHintWhenWonIsNoOp() async {
        let sut = BoardViewModel(initialState: wonState(), solver: FakeSolver(first: Move(from: 0, to: 1)))
        XCTAssertTrue(sut.isWon)

        sut.requestHint()
        await sut.hintTask?.value

        XCTAssertNil(sut.hintMove)
        XCTAssertFalse(sut.isHinting)
    }

    func testRequestHintWithRealSolverIsLegal() async {
        // No fake: the production Solver must return a genuinely legal first move.
        let sut = BoardViewModel(initialState: solvableState())

        sut.requestHint()
        await sut.hintTask?.value

        let move = try? XCTUnwrap(sut.hintMove)
        XCTAssertNotNil(move)
        if let move { XCTAssertTrue(sut.gameState.isLegal(move)) }
    }

    // MARK: - Hint feedback (E14.7)

    func testRequestingHintPlaysHintCue() async {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(
            initialState: solvableState(),
            solver: FakeSolver(first: Move(from: 0, to: 2)),
            feedback: spy
        )

        sut.requestHint()
        await sut.hintTask?.value

        XCTAssertEqual(spy.events, [.hint])
    }

    func testRequestingHintOnWonBoardPlaysNoCue() async {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(
            initialState: wonState(),
            solver: FakeSolver(first: Move(from: 0, to: 1)),
            feedback: spy
        )

        sut.requestHint()
        await sut.hintTask?.value

        XCTAssertEqual(spy.events, [], "a won board can't be hinted, so nothing should fire")
    }

    func testHintWithNoSolutionPlaysNoCue() async {
        let spy = FeedbackSpy()
        let sut = BoardViewModel(
            initialState: solvableState(),
            solver: FakeSolver(first: nil), // solver finds no move
            feedback: spy
        )

        sut.requestHint()
        await sut.hintTask?.value

        XCTAssertNil(sut.hintMove)
        XCTAssertEqual(spy.events, [], "no surfaced move means no nudge cue")
    }

    // MARK: - Clearing

    func testTapClearsHint() async {
        let sut = BoardViewModel(initialState: solvableState(), solver: FakeSolver(first: Move(from: 0, to: 2)))
        sut.requestHint()
        await sut.hintTask?.value
        XCTAssertNotNil(sut.hintMove)

        sut.tap(0) // lift a tube

        XCTAssertNil(sut.hintMove)
        XCTAssertFalse(sut.isHintSource(0))
    }

    func testUndoClearsHint() async {
        let sut = BoardViewModel(initialState: solvableState(), solver: FakeSolver(first: Move(from: 0, to: 2)))
        sut.tap(0)
        sut.tap(2) // a legal move so there's something to undo
        sut.requestHint()
        await sut.hintTask?.value
        XCTAssertNotNil(sut.hintMove)

        sut.undo()

        XCTAssertNil(sut.hintMove)
    }

    func testRestartClearsHint() async {
        let sut = BoardViewModel(initialState: solvableState(), solver: FakeSolver(first: Move(from: 0, to: 2)))
        sut.requestHint()
        await sut.hintTask?.value
        XCTAssertNotNil(sut.hintMove)

        sut.restart()

        XCTAssertNil(sut.hintMove)
    }
}
