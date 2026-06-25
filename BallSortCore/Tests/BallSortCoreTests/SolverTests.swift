import Testing
@testable import BallSortCore

@Suite("Solver")
struct SolverTests {
    private func state(_ tubes: [[BallColor]], capacity: Int = 4) -> GameState {
        GameState(tubes: tubes.map { Tube(balls: $0, capacity: capacity) }, capacity: capacity)
    }

    /// Replays `moves` from `start`, asserting each is legal in sequence, and
    /// returns the final state.
    private func replay(_ moves: [Move], from start: GameState) -> GameState {
        var current = start
        for move in moves {
            let next = current.apply(move)
            #expect(next != nil, "move \(move) was illegal mid-sequence")
            current = next ?? current
        }
        return current
    }

    // MARK: - Edge cases

    @Test("solve: an already-won state returns an empty move list")
    func alreadyWonReturnsEmpty() {
        let game = state([[], [.blue, .blue, .blue, .blue], [.green, .green, .green, .green]])
        let solution = Solver().solve(game)
        #expect(solution == [])
    }

    @Test("solve: a trivial one-move state returns a one-move winning solution")
    func trivialOneMove() throws {
        // One blue out of place; sliding it home wins in a single move.
        let game = state([[.blue, .blue, .blue], [.blue], []])
        let solution = try #require(Solver().solve(game))
        #expect(solution.count == 1)
        #expect(replay(solution, from: game).isWon)
    }

    // MARK: - Solvable positions

    @Test("solve: a scrambled but solvable position returns a winning, legal sequence")
    func scrambledSolvable() throws {
        // 2 colors, capacity 3, two filled tubes interleaved + one spare empty tube.
        let game = state(
            [[.blue, .green, .blue], [.green, .blue, .green], []],
            capacity: 3
        )
        let solution = try #require(Solver().solve(game))
        let final = replay(solution, from: game)
        #expect(final.isWon)
    }

    @Test("solve: a three-color scramble is solved")
    func threeColorScramble() throws {
        let game = state(
            [
                [.yellow, .blue, .green, .yellow],
                [.blue, .green, .yellow, .blue],
                [.green, .yellow, .blue, .green],
                [],
                []
            ],
            capacity: 4
        )
        let solution = try #require(Solver().solve(game))
        #expect(replay(solution, from: game).isWon)
    }

    // MARK: - Unsolvable positions

    @Test("solve: a deadlocked full board with no empty tube returns nil")
    func unsolvableReturnsNil() {
        // Every tube full, mixed, no empty tube => no legal move at all => unsolvable.
        let game = state(
            [[.blue, .green], [.green, .blue]],
            capacity: 2
        )
        #expect(game.legalMoves().isEmpty)
        #expect(Solver().solve(game) == nil)
    }

    @Test("isSolvable: matches solve != nil for both a solvable and an unsolvable state")
    func isSolvableDefault() {
        let solver = Solver()
        let solvable = state([[.blue, .blue, .blue], [.blue], []])
        let unsolvable = state([[.blue, .green], [.green, .blue]], capacity: 2)
        #expect(solver.isSolvable(solvable))
        #expect(!solver.isSolvable(unsolvable))
    }

    // MARK: - Shortest-path property

    @Test("solve: never returns a sequence longer than a known solution")
    func shortestPathNoLongerThanKnown() throws {
        // Scramble a solved board with exactly 3 reverse (legal) moves, so a
        // 3-move solution provably exists. BFS must not return anything longer.
        // tube2 starts empty; each move lifts a blue onto it (same-color stacking).
        let solved = state([[.blue, .blue, .blue, .blue], [.green, .green, .green, .green], []])
        var scrambled = solved
        let reverseMoves = [Move(from: 0, to: 2), Move(from: 0, to: 2), Move(from: 0, to: 2)]
        for move in reverseMoves {
            scrambled = try #require(scrambled.apply(move))
        }
        let solution = try #require(Solver().solve(scrambled))
        #expect(solution.count <= reverseMoves.count)
        #expect(replay(solution, from: scrambled).isWon)
    }

    @Test("solve: returns the exact shortest length on a known two-move position")
    func exactShortestLength() throws {
        // Two balls out of place, each home in one move; no shorter sequence exists.
        let game = state([[.blue, .blue, .blue], [.green, .green, .green], [.green, .blue]])
        let solution = try #require(Solver().solve(game))
        #expect(solution.count == 2)
        #expect(replay(solution, from: game).isWon)
    }

    // MARK: - Legality of the returned sequence

    @Test("solve: every returned move is legal when applied in sequence")
    func returnedMovesAreLegalInSequence() throws {
        let game = state(
            [[.blue, .green, .blue], [.green, .blue, .green], []],
            capacity: 3
        )
        let solution = try #require(Solver().solve(game))
        var current = game
        for move in solution {
            #expect(current.isLegal(move))
            current = try #require(current.apply(move))
        }
        #expect(current.isWon)
    }

    // MARK: - Determinism

    @Test("solve: the same input twice yields the same result")
    func deterministic() {
        let game = state(
            [[.blue, .green, .blue], [.green, .blue, .green], []],
            capacity: 3
        )
        let solver = Solver()
        #expect(solver.solve(game) == solver.solve(game))
    }
}
