import Testing
@testable import BallSortCore

@Suite("GameState")
struct GameStateTests {
    private func state(_ tubes: [[BallColor]], capacity: Int = 4) -> GameState {
        GameState(tubes: tubes.map { Tube(balls: $0, capacity: capacity) }, capacity: capacity)
    }

    // MARK: - Legality matrix

    @Test("legal: move onto an empty tube")
    func legalOntoEmpty() {
        let game = state([[.yellow], []])
        #expect(game.isLegal(Move(from: 0, to: 1)))
    }

    @Test("legal: move onto same-color non-full tube")
    func legalOntoSameColorNonFull() {
        let game = state([[.blue], [.blue]])
        #expect(game.isLegal(Move(from: 0, to: 1)))
    }

    @Test("illegal: move onto a different color")
    func illegalDifferentColor() {
        let game = state([[.blue], [.green]])
        #expect(!game.isLegal(Move(from: 0, to: 1)))
    }

    @Test("illegal: move onto a full tube (even same color)")
    func illegalOntoFull() {
        let game = state([[.blue], [.blue, .blue, .blue, .blue]])
        #expect(!game.isLegal(Move(from: 0, to: 1)))
    }

    @Test("illegal: move from an empty source")
    func illegalFromEmpty() {
        let game = state([[], [.blue]])
        #expect(!game.isLegal(Move(from: 0, to: 1)))
    }

    @Test("illegal: self-move (from == to)")
    func illegalSelfMove() {
        let game = state([[.blue], [.green]])
        #expect(!game.isLegal(Move(from: 0, to: 0)))
    }

    @Test("illegal: out-of-bounds indices")
    func illegalOutOfBounds() {
        let game = state([[.blue], []])
        #expect(!game.isLegal(Move(from: 5, to: 1)))
        #expect(!game.isLegal(Move(from: 0, to: 9)))
        #expect(!game.isLegal(Move(from: -1, to: 0)))
    }

    // MARK: - apply

    @Test("apply: legal move moves source top onto same-color dest top")
    func applyLegal() {
        let game = state([[.yellow, .blue], [.blue]])
        let result = game.apply(Move(from: 0, to: 1))
        let expected = state([[.yellow], [.blue, .blue]])
        #expect(result == expected)
    }

    @Test("apply: legal move onto empty tube")
    func applyOntoEmpty() {
        let game = state([[.yellow, .blue], []])
        let result = game.apply(Move(from: 0, to: 1))
        let expected = state([[.yellow], [.blue]])
        #expect(result == expected)
    }

    @Test("apply: illegal move returns nil")
    func applyIllegal() {
        let game = state([[.blue], [.green]])
        #expect(game.apply(Move(from: 0, to: 1)) == nil)
    }

    @Test("apply: does not mutate self")
    func applyIsPure() {
        let game = state([[.yellow, .blue], []])
        let before = game
        _ = game.apply(Move(from: 0, to: 1))
        #expect(game == before)
    }

    // MARK: - isWon

    @Test("isWon: solved arrangement (empty + full single-color) is true")
    func isWonTrue() {
        let game = state([[], [.blue, .blue, .blue, .blue], [.green, .green, .green, .green]])
        #expect(game.isWon)
    }

    @Test("isWon: unsolved arrangement is false")
    func isWonFalse() {
        let game = state([[.blue, .green], [.green, .blue], []])
        #expect(!game.isWon)
    }

    @Test("isWon: full mixed tube is not a win")
    func isWonFullMixedFalse() {
        let game = state([[.blue, .green, .blue, .green]])
        #expect(!game.isWon)
    }

    // MARK: - legalMoves

    @Test("legalMoves: returns exactly the expected set on a hand-built state")
    func legalMovesExpected() {
        // tube0 top=blue, tube1 top=green, tube2 empty.
        let game = state([[.blue], [.green], []])
        let moves = Set(game.legalMoves())
        // blue can go to empty tube2; green can go to empty tube2.
        // blue->green and green->blue are illegal (color mismatch).
        let expected: Set<Move> = [Move(from: 0, to: 2), Move(from: 1, to: 2)]
        #expect(moves == expected)
    }

    @Test("legalMoves: empty board yields no moves")
    func legalMovesEmpty() {
        let game = state([[], []])
        #expect(game.legalMoves().isEmpty)
    }
}
