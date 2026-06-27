import XCTest
import BallSortCore
@testable import BallSortApp

/// Exhaustive intent → state transition coverage for `BoardViewModel`.
/// Move legality lives in `BallSortCore`; these tests only assert the view
/// model's selection / move-count / lastDrop bookkeeping and restart reset.
///
/// Written in XCTest (not Swift Testing): mixing both frameworks in one app
/// test bundle makes `xcodebuild test` launch the runner twice and report a
/// spurious teardown crash even when every test passes. The existing
/// `SmokeTests` are XCTest, so we stay on XCTest to keep the bundle single-runner.
@MainActor
final class BoardViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private let capacity = 4

    /// Two tubes: a non-empty source (yellow on top) and an empty destination.
    /// A legal move exists (yellow → empty).
    private func legalMoveState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow, .yellow], capacity: capacity),
                Tube(balls: [], capacity: capacity)
            ],
            capacity: capacity
        )
    }

    /// Two non-empty tubes whose tops mismatch (yellow vs blue): no legal move
    /// between them, but each is selectable.
    private func colorMismatchState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: capacity),
                Tube(balls: [.blue], capacity: capacity)
            ],
            capacity: capacity
        )
    }

    /// Source has a yellow top; destination is full — the move is illegal because
    /// the destination cannot accept another ball.
    private func fullDestinationState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: 1),
                Tube(balls: [.blue], capacity: 1)
            ],
            capacity: 1
        )
    }

    /// A solved board: each tube empty or a finished single-color stack.
    private func wonState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow, .yellow], capacity: 2),
                Tube(balls: [], capacity: 2)
            ],
            capacity: 2
        )
    }

    // MARK: - Initial state

    func testInitialStateIsClean() {
        let sut = BoardViewModel(initialState: legalMoveState())
        XCTAssertNil(sut.selectedTube)
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertNil(sut.lastDrop)
        XCTAssertFalse(sut.isWon)
    }

    // MARK: - Selection

    func testTappingNonEmptyTubeLifts() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0)
        XCTAssertEqual(sut.selectedTube, 0)
        XCTAssertTrue(sut.isSelected(0))
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertNil(sut.lastDrop)
    }

    func testTappingEmptyTubeIsNoOp() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(1) // tube 1 is empty
        XCTAssertNil(sut.selectedTube)
        XCTAssertEqual(sut.moveCount, 0)
    }

    func testTappingSelectedTubeCancels() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0)
        XCTAssertEqual(sut.selectedTube, 0)
        sut.tap(0)
        XCTAssertNil(sut.selectedTube)
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertNil(sut.lastDrop)
    }

    func testCancelSelectionClearsSelection() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0)
        sut.cancelSelection()
        XCTAssertNil(sut.selectedTube)
        XCTAssertNil(sut.lastDrop)
    }

    // MARK: - Legal move

    func testLegalMoveApplies() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0) // lift yellow
        sut.tap(1) // drop on empty
        XCTAssertEqual(sut.moveCount, 1)
        XCTAssertEqual(sut.lastDrop, 1)
        XCTAssertNil(sut.selectedTube)
        XCTAssertEqual(sut.gameState.tubes[0].balls, [.yellow])
        XCTAssertEqual(sut.gameState.tubes[1].balls, [.yellow])
    }

    // MARK: - Pour-arc seam (E14.3)

    func testLegalMoveRecordsLastMoveWithEndpointsAndColor() {
        let sut = BoardViewModel(initialState: legalMoveState())
        XCTAssertNil(sut.lastMove)
        sut.tap(0) // lift yellow
        sut.tap(1) // drop on empty
        XCTAssertEqual(sut.lastMove, AnimatedMove(from: 0, to: 1, color: .yellow, nonce: 1))
    }

    func testEachLegalMoveIncrementsTheNonce() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0); sut.tap(1) // yellow 0 -> 1
        XCTAssertEqual(sut.lastMove?.nonce, 1)
        sut.tap(0); sut.tap(1) // yellow 0 -> 1 again (onto matching top)
        XCTAssertEqual(sut.lastMove, AnimatedMove(from: 0, to: 1, color: .yellow, nonce: 2))
    }

    func testIllegalMoveLeavesLastMoveUnchanged() {
        let sut = BoardViewModel(initialState: colorMismatchState())
        sut.tap(0) // select yellow
        sut.tap(1) // reject onto blue
        XCTAssertNil(sut.lastMove, "a rejected move must not fire a pour flight")
    }

    func testUndoDoesNotRetriggerLastMove() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0); sut.tap(1)
        let afterMove = sut.lastMove
        sut.undo()
        XCTAssertEqual(sut.lastMove, afterMove, "undo must not bump the nonce or replay a flight")
    }

    func testLegalMoveOntoSameColorTopApplies() {
        let state = GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: capacity),
                Tube(balls: [.yellow], capacity: capacity)
            ],
            capacity: capacity
        )
        let sut = BoardViewModel(initialState: state)
        sut.tap(0)
        sut.tap(1)
        XCTAssertEqual(sut.moveCount, 1)
        XCTAssertEqual(sut.lastDrop, 1)
        XCTAssertTrue(sut.gameState.tubes[0].isEmpty)
        XCTAssertEqual(sut.gameState.tubes[1].balls, [.yellow, .yellow])
    }

    // MARK: - Illegal move

    func testIllegalMoveColorMismatchSwitchesSelection() {
        let sut = BoardViewModel(initialState: colorMismatchState())
        sut.tap(0) // lift yellow
        sut.tap(1) // blue top — illegal
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertNil(sut.lastDrop)
        XCTAssertEqual(sut.selectedTube, 1) // re-target to the non-empty tapped tube
        XCTAssertEqual(sut.gameState, colorMismatchState()) // unchanged
    }

    func testIllegalMoveFullDestinationSwitchesSelection() {
        let sut = BoardViewModel(initialState: fullDestinationState())
        let original = fullDestinationState()
        sut.tap(0) // lift yellow
        sut.tap(1) // destination full — illegal
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertNil(sut.lastDrop)
        XCTAssertEqual(sut.selectedTube, 1)
        XCTAssertEqual(sut.gameState, original)
    }

    func testIllegalMoveRetargetsToNonEmptyTube() {
        // Lifting from tube 2 and tapping tube 0 (mismatched top) is illegal,
        // so the selection re-targets to tube 0 because it is non-empty.
        let state = GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: capacity),
                Tube(balls: [], capacity: capacity),
                Tube(balls: [.blue], capacity: capacity)
            ],
            capacity: capacity
        )
        let sut = BoardViewModel(initialState: state)
        sut.tap(2) // lift blue
        sut.tap(0) // yellow top, illegal -> re-target to non-empty tube 0
        XCTAssertEqual(sut.selectedTube, 0)
        XCTAssertEqual(sut.moveCount, 0)
    }

    func testIllegalMoveOntoEmptyOrInvalidTargetClearsSelection() {
        // The clear branch fires when an illegal move targets a tube the view
        // model treats as empty. An out-of-bounds index is illegal in Core and
        // treated as empty by the view model, exercising that branch.
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0) // lift yellow
        sut.tap(99) // out of bounds: illegal, treated as empty -> clear
        XCTAssertNil(sut.selectedTube)
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertNil(sut.lastDrop)
        XCTAssertEqual(sut.gameState, legalMoveState())
    }

    // MARK: - Illegal-move shake nonce (E8.3)

    func testIllegalMoveBumpsNonce() {
        let sut = BoardViewModel(initialState: colorMismatchState())
        XCTAssertEqual(sut.illegalMoveNonce, 0)
        sut.tap(0) // lift yellow (selection only — no bump)
        XCTAssertEqual(sut.illegalMoveNonce, 0)
        sut.tap(1) // blue top — illegal -> bump
        XCTAssertEqual(sut.illegalMoveNonce, 1)
    }

    func testLegalMoveDoesNotBumpNonce() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0) // lift yellow
        sut.tap(1) // legal move -> no bump
        XCTAssertEqual(sut.illegalMoveNonce, 0)
    }

    func testPlainSelectionDoesNotBumpNonce() {
        let sut = BoardViewModel(initialState: colorMismatchState())
        sut.tap(0) // lift (select) — no source yet, so the else branch never runs
        XCTAssertEqual(sut.illegalMoveNonce, 0)
        sut.tap(0) // tap same tube -> cancel selection, still no bump
        XCTAssertEqual(sut.illegalMoveNonce, 0)
    }

    // MARK: - Restart

    func testRestartResetsEverything() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0)
        sut.tap(1) // apply a move
        XCTAssertEqual(sut.moveCount, 1)
        sut.tap(1) // lift to dirty selection
        sut.restart()
        XCTAssertEqual(sut.gameState, legalMoveState())
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertNil(sut.selectedTube)
        XCTAssertNil(sut.lastDrop)
    }

    // MARK: - Win

    func testIsWonReflectsSolvedState() {
        let sut = BoardViewModel(initialState: wonState())
        XCTAssertTrue(sut.isWon)
    }

    func testIsWonBecomesTrueAfterWinningMove() {
        // Two yellows split across tubes; consolidating them wins (capacity 2).
        let state = GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: 2),
                Tube(balls: [.yellow], capacity: 2)
            ],
            capacity: 2
        )
        let sut = BoardViewModel(initialState: state)
        XCTAssertFalse(sut.isWon)
        sut.tap(0)
        sut.tap(1)
        XCTAssertTrue(sut.isWon)
    }
}
