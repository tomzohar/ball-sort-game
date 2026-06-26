import Testing
@testable import BallSortCore

@Suite("DifficultyGrader")
struct DifficultyGraderTests {
    // MARK: - Helpers

    /// A `Solving` fake that always reports a fixed-length solution, so tests can
    /// pin min-moves deterministically without depending on the real solver.
    private struct FakeSolver: Solving {
        let moves: Int
        func solve(_ state: GameState) -> [Move]? {
            guard moves >= 0 else { return nil }
            return Array(repeating: Move(from: 0, to: 1), count: moves)
        }
    }

    /// A `Solving` fake that always declares the position unsolvable.
    private struct UnsolvableSolver: Solving {
        func solve(_ state: GameState) -> [Move]? { nil }
    }

    private func state(_ tubes: [[BallColor]], capacity: Int = 4) -> GameState {
        GameState(tubes: tubes.map { Tube(balls: $0, capacity: capacity) }, capacity: capacity)
    }

    /// A board with `colors` full single-color tubes plus `emptyTubes` empty tubes.
    private func board(colors: Int, emptyTubes: Int, capacity: Int = 4) -> GameState {
        let palette = Array(BallColor.allCases.prefix(colors))
        var tubes = palette.map { Tube(balls: Array(repeating: $0, count: capacity), capacity: capacity) }
        tubes.append(contentsOf: (0..<emptyTubes).map { _ in Tube(balls: [], capacity: capacity) })
        return GameState(tubes: tubes, capacity: capacity)
    }

    // MARK: - Monotonicity

    @Test("score is strictly increasing in min-moves, holding colors and tubes fixed")
    func monotonicInMinMoves() {
        let grader = DifficultyGrader()
        let game = board(colors: 3, emptyTubes: 2)
        let low = grader.grade(game, using: FakeSolver(moves: 5))
        let high = grader.grade(game, using: FakeSolver(moves: 30))
        #expect(high.score > low.score)
        #expect(high >= low)
    }

    @Test("score does not decrease when colors increase, holding tubes and min-moves fixed")
    func monotonicInColors() {
        let grader = DifficultyGrader()
        // Same total tube count (6) and same fake min-moves; only color count differs.
        let fewColors = board(colors: 2, emptyTubes: 4)
        let manyColors = board(colors: 4, emptyTubes: 2)
        let low = grader.grade(fewColors, using: FakeSolver(moves: 10))
        let high = grader.grade(manyColors, using: FakeSolver(moves: 10))
        #expect(high.score >= low.score)
    }

    @Test("score does not decrease when tubes increase, holding colors and min-moves fixed")
    func monotonicInTubes() {
        let grader = DifficultyGrader()
        // Same color count (3) and same fake min-moves; only spare-tube count differs.
        let fewTubes = board(colors: 3, emptyTubes: 1)
        let manyTubes = board(colors: 3, emptyTubes: 4)
        let low = grader.grade(fewTubes, using: FakeSolver(moves: 10))
        let high = grader.grade(manyTubes, using: FakeSolver(moves: 10))
        #expect(high.score >= low.score)
    }

    // MARK: - Band boundaries (pins the formula)

    @Test("a tiny, near-solved level grades trivial")
    func trivialBand() {
        let grader = DifficultyGrader()
        // 2 colors, 3 tubes, 1 move: score = 1*3 + 3 + 2 = 8 -> trivial.
        let game = board(colors: 2, emptyTubes: 1)
        let graded = grader.grade(game, using: FakeSolver(moves: 1))
        #expect(graded.score == 8)
        #expect(graded.band == .trivial)
    }

    @Test("a small easy level grades easy")
    func easyBand() {
        let grader = DifficultyGrader()
        // 3 colors, 4 tubes (1 empty), 8 moves: score = 8*3 + 4 + 3 = 31 -> easy.
        let game = board(colors: 3, emptyTubes: 1)
        let graded = grader.grade(game, using: FakeSolver(moves: 8))
        #expect(graded.score == 31)
        #expect(graded.band == .easy)
    }

    @Test("a mid-size level grades medium")
    func mediumBand() {
        let grader = DifficultyGrader()
        // 5 colors, 7 tubes (2 empty), 18 moves: score = 18*3 + 7 + 5 = 66 -> medium.
        let game = board(colors: 5, emptyTubes: 2)
        let graded = grader.grade(game, using: FakeSolver(moves: 18))
        #expect(graded.score == 66)
        #expect(graded.band == .medium)
    }

    @Test("a large, move-heavy level grades hard")
    func hardBand() {
        let grader = DifficultyGrader()
        // 6 colors, 8 tubes (2 empty), 35 moves: score = 35*3 + 8 + 6 = 119 -> hard.
        let game = board(colors: 6, emptyTubes: 2)
        let graded = grader.grade(game, using: FakeSolver(moves: 35))
        #expect(graded.score == 119)
        #expect(graded.band == .hard)
    }

    @Test("a very deep level grades expert")
    func expertBand() {
        let grader = DifficultyGrader()
        // 6 colors, 9 tubes, 60 moves: score = 60*3 + 9 + 6 = 195 -> expert.
        let game = board(colors: 6, emptyTubes: 3)
        let graded = grader.grade(game, using: FakeSolver(moves: 60))
        #expect(graded.score == 195)
        #expect(graded.band == .expert)
    }

    // MARK: - Color counting

    @Test("color count counts distinct colors present, not tubes")
    func distinctColorCounting() {
        let grader = DifficultyGrader()
        // Two tubes, but only one distinct color across the board.
        let game = state([[.blue, .blue], [.blue], []], capacity: 4)
        // colors = 1, tubes = 3, moves = 0 -> score = 0 + 3 + 1 = 4.
        let graded = grader.grade(game, using: FakeSolver(moves: 0))
        #expect(graded.score == 4)
    }

    // MARK: - Comparable

    @Test("a clearly-harder config sorts after an easier one")
    func comparableSorts() {
        let grader = DifficultyGrader()
        let easy = grader.grade(board(colors: 2, emptyTubes: 1), using: FakeSolver(moves: 2))
        let hard = grader.grade(board(colors: 6, emptyTubes: 3), using: FakeSolver(moves: 40))
        #expect(easy < hard)
        #expect([hard, easy].sorted() == [easy, hard])
    }

    // MARK: - Equatable

    @Test("two equally-dimensioned levels grade equal")
    func equalGrades() {
        let grader = DifficultyGrader()
        let a = grader.grade(board(colors: 3, emptyTubes: 2), using: FakeSolver(moves: 12))
        let b = grader.grade(board(colors: 3, emptyTubes: 2), using: FakeSolver(moves: 12))
        #expect(a == b)
    }

    // MARK: - Unsolvable handling

    @Test("an unsolvable state grades the maximum band, never traps")
    func unsolvableGradesMax() {
        let grader = DifficultyGrader()
        let game = board(colors: 3, emptyTubes: 2)
        let graded = grader.grade(game, using: UnsolvableSolver())
        #expect(graded.band == .expert)
        #expect(graded == Difficulty.maximum)
    }

    // MARK: - Integration with the real solver

    @Test("grades a hand-built solvable level with the real Solver without trapping")
    func realSolverIntegration() {
        let grader = DifficultyGrader()
        let game = state([[.blue, .blue, .blue], [.blue], []], capacity: 4)
        let graded = grader.grade(game, using: Solver())
        // One blue out of place -> 1 min-move; should be the easiest, trivial band.
        #expect(graded.band == .trivial)
        #expect(graded.score > 0)
    }

    @Test("grades a Generator-built level with the real Solver")
    func generatorIntegration() {
        let grader = DifficultyGrader()
        let game = Generator().generate(colors: 3, capacity: 4, emptyTubes: 2, minMoves: 10, seed: 42)
        let graded = grader.grade(game, using: Solver())
        #expect(graded.score > 0)
    }
}
