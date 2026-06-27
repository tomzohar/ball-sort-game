import XCTest
import BallSortCore
@testable import BallSortApp

/// Covers the E5 game-loop additions to `BoardViewModel`: undo history, sorted
/// count, the elapsed-time clock, generator-driven level advancement, and async
/// difficulty grading. Move/selection bookkeeping is covered by
/// `BoardViewModelTests`. XCTest (not Swift Testing) to keep the bundle
/// single-runner — see the note in `BoardViewModelTests`.
@MainActor
final class GameLoopViewModelTests: XCTestCase {

    // MARK: - Fixtures & fakes

    private let capacity = 4

    /// Two yellows over an empty tube: a single legal move exists.
    private func legalMoveState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.yellow, .yellow], capacity: capacity),
                Tube(balls: [], capacity: capacity)
            ],
            capacity: capacity
        )
    }

    /// A board with one finished tube and one mixed tube.
    private func partlySortedState() -> GameState {
        GameState(
            tubes: [
                Tube(balls: [.green, .green], capacity: 2), // complete
                Tube(balls: [.blue, .yellow], capacity: 2), // mixed
                Tube(balls: [], capacity: 2)
            ],
            capacity: 2
        )
    }

    /// Generates a deterministic, never-won board whose green count tracks
    /// `minMoves`, so successive levels (with a rising floor) differ. Synchronous and
    /// solver-free, so VM generation tests stay fast and deterministic.
    private struct FakeGenerator: LevelGenerating {
        func generate<R: RandomNumberGenerator>(
            colors: Int, capacity: Int, emptyTubes: Int, minMoves: Int, using generator: inout R
        ) -> GameState {
            let greens = min(max(1, capacity - 1), max(1, minMoves - 9))
            var tubes = [
                Tube(balls: [.yellow, .blue], capacity: capacity), // mixed -> never won
                Tube(balls: Array(repeating: .green, count: greens), capacity: capacity)
            ]
            tubes.append(contentsOf: (0..<emptyTubes).map { _ in Tube(balls: [], capacity: capacity) })
            return GameState(tubes: tubes, capacity: capacity)
        }
    }

    private struct FakeSolver: Solving {
        let moves: Int
        func solve(_ state: GameState) -> [Move]? {
            Array(repeating: Move(from: 0, to: 1), count: moves)
        }
    }

    /// A small curve: constant colors/empties, a rising min-moves floor (+4/level).
    private func smallCurve(baseColors: Int = 3, maxColors: Int = 5) -> DifficultyCurve {
        DifficultyCurve(
            baseColors: baseColors, maxColors: maxColors, colorsEveryLevels: 10,
            baseCapacity: capacity,
            baseEmptyTubes: 2, minEmptyTubes: 1, emptyDropEveryLevels: 100,
            baseMinMoves: 10, minMovesPerLevel: 4, maxMinMoves: 100
        )
    }

    /// A mutable clock backing an injectable `now` closure.
    private final class Clock { var t: TimeInterval = 0 }

    // MARK: - Undo

    func testCanUndoIsFalseInitially() {
        let sut = BoardViewModel(initialState: legalMoveState())
        XCTAssertFalse(sut.canUndo)
    }

    func testUndoRevertsLastMove() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0)
        sut.tap(1) // legal move applied
        XCTAssertEqual(sut.moveCount, 1)
        XCTAssertTrue(sut.canUndo)

        sut.undo()
        XCTAssertEqual(sut.gameState, legalMoveState())
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertFalse(sut.canUndo)
        XCTAssertNil(sut.selectedTube)
        XCTAssertNil(sut.lastDrop)
    }

    func testUndoWithNoHistoryIsNoOp() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.undo()
        XCTAssertEqual(sut.gameState, legalMoveState())
        XCTAssertEqual(sut.moveCount, 0)
    }

    func testRestartClearsUndoHistory() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.tap(0)
        sut.tap(1)
        XCTAssertTrue(sut.canUndo)
        sut.restart()
        XCTAssertFalse(sut.canUndo)
    }

    // MARK: - Sorted count

    func testSortedCountAndTubeCount() {
        let sut = BoardViewModel(initialState: partlySortedState())
        XCTAssertEqual(sut.sortedCount, 1)
        XCTAssertEqual(sut.tubeCount, 3)
    }

    // MARK: - Timer

    func testElapsedTracksInjectedClock() {
        let clock = Clock()
        let sut = BoardViewModel(initialState: legalMoveState(), now: { clock.t })
        XCTAssertEqual(sut.elapsed, 0, accuracy: 0.0001)
        clock.t = 5
        XCTAssertEqual(sut.elapsed, 5, accuracy: 0.0001)
    }

    func testTimerFreezesOnWin() {
        // Two yellows that merge into a win at capacity 2.
        let state = GameState(
            tubes: [
                Tube(balls: [.yellow], capacity: 2),
                Tube(balls: [.yellow], capacity: 2)
            ],
            capacity: 2
        )
        let clock = Clock()
        let sut = BoardViewModel(initialState: state, now: { clock.t })
        clock.t = 7
        sut.tap(0)
        sut.tap(1) // winning move at t = 7
        XCTAssertTrue(sut.isWon)
        clock.t = 100
        XCTAssertEqual(sut.elapsed, 7, accuracy: 0.0001) // frozen at win time
    }

    // MARK: - Generation

    func testFirstLevelGeneratesAndClearsIsGenerating() async {
        let sut = BoardViewModel(
            generator: FakeGenerator(), solver: FakeSolver(moves: 5),
            curve: smallCurve(), seed: 1
        )
        await sut.generateTask?.value
        XCTAssertFalse(sut.isGenerating)
        XCTAssertEqual(sut.level, 1)
        XCTAssertFalse(sut.gameState.isWon)
    }

    // MARK: - Level advancement

    func testNextLevelAdvancesAlongCurve() async {
        let sut = BoardViewModel(
            generator: FakeGenerator(), solver: FakeSolver(moves: 5),
            curve: smallCurve(), seed: 1
        )
        await sut.generateTask?.value
        XCTAssertEqual(sut.level, 1)
        let firstGreens = sut.gameState.tubes[1].balls.count

        sut.nextLevel()
        await sut.generateTask?.value
        XCTAssertEqual(sut.level, 2)
        XCTAssertFalse(sut.isWon)
        XCTAssertEqual(sut.moveCount, 0)
        XCTAssertFalse(sut.canUndo)
        // The curve raised the min-moves floor, so the generated board differs.
        XCTAssertGreaterThan(sut.gameState.tubes[1].balls.count, firstGreens)
    }

    func testTimerStartsWhenLevelInstalledAndResetsOnNextLevel() async {
        let clock = Clock()
        clock.t = 100
        let sut = BoardViewModel(
            generator: FakeGenerator(), solver: FakeSolver(moves: 5),
            curve: smallCurve(), seed: 1, now: { clock.t }
        )
        await sut.generateTask?.value // installed at t = 100
        XCTAssertEqual(sut.elapsed, 0, accuracy: 0.0001)
        clock.t = 105
        XCTAssertEqual(sut.elapsed, 5, accuracy: 0.0001)

        sut.nextLevel()
        await sut.generateTask?.value // re-installed at t = 105
        XCTAssertEqual(sut.elapsed, 0, accuracy: 0.0001)
        clock.t = 108
        XCTAssertEqual(sut.elapsed, 3, accuracy: 0.0001)
    }

    func testNextLevelIsNoOpForPinnedBoard() {
        let sut = BoardViewModel(initialState: legalMoveState())
        sut.nextLevel()
        XCTAssertEqual(sut.level, 1)
        XCTAssertEqual(sut.gameState, legalMoveState())
    }

    // MARK: - Difficulty grading

    func testGradingWithinBoundsSetsExactDifficulty() async {
        let solver = FakeSolver(moves: 5)
        let sut = BoardViewModel(
            generator: FakeGenerator(), solver: solver,
            curve: smallCurve(), seed: 1
        )
        await sut.generateTask?.value
        await sut.gradingTask?.value
        let expected = DifficultyGrader().grade(sut.gameState, using: solver)
        XCTAssertEqual(sut.difficulty, expected)
        XCTAssertEqual(sut.difficultyBand, expected.band)
    }

    func testGradingSkippedAboveColorBoundFallsBackToEstimate() async {
        // 6 colors exceeds the solver-feasible grading bound, so no exact grade runs.
        let curve = smallCurve(baseColors: 6, maxColors: 6)
        let sut = BoardViewModel(
            generator: FakeGenerator(), solver: FakeSolver(moves: 5),
            curve: curve, seed: 1
        )
        await sut.generateTask?.value
        XCTAssertNil(sut.gradingTask)
        XCTAssertNil(sut.difficulty)
        XCTAssertEqual(sut.difficultyBand, curve.estimatedBand(forLevel: 1))
    }
}
