/// An immutable snapshot of a ball-sort puzzle: the tubes and their shared capacity.
///
/// All gameplay is expressed as pure transformations: `apply` returns a brand-new
/// `GameState` and never mutates `self`, so states can be freely compared, hashed,
/// and explored by the solver. Move legality follows the *classic* rule (memory m1):
/// a ball may move only onto an empty tube, or onto a non-full tube whose top ball
/// matches the moving ball's color.
public struct GameState: Equatable, Hashable, Sendable, Codable {
    /// The tubes that make up the board.
    public var tubes: [Tube]
    /// The capacity shared by every tube in this puzzle.
    public var capacity: Int

    public init(tubes: [Tube], capacity: Int) {
        self.tubes = tubes
        self.capacity = capacity
    }

    /// Whether `move` is a legal classic move from this state.
    ///
    /// Requires: both indices in bounds and distinct, a non-empty source, a non-full
    /// destination, and either an empty destination or a color-matched destination top.
    public func isLegal(_ move: Move) -> Bool {
        guard tubes.indices.contains(move.from),
              tubes.indices.contains(move.to),
              move.from != move.to else { return false }

        let source = tubes[move.from]
        let destination = tubes[move.to]

        guard let moving = source.top else { return false } // source must be non-empty
        guard !destination.isFull else { return false }

        return destination.isEmpty || destination.top == moving
    }

    /// Every legal move available from this state, in `(from, to)` index order.
    public func legalMoves() -> [Move] {
        var moves: [Move] = []
        for from in tubes.indices {
            for to in tubes.indices {
                let move = Move(from: from, to: to)
                if isLegal(move) {
                    moves.append(move)
                }
            }
        }
        return moves
    }

    /// The state produced by applying `move`, or `nil` if the move is illegal.
    ///
    /// Pure: `self` is never mutated. The source's top ball is removed and pushed
    /// onto the destination.
    public func apply(_ move: Move) -> GameState? {
        guard isLegal(move) else { return nil }

        var next = self
        guard let moving = next.tubes[move.from].balls.popLast() else { return nil }
        next.tubes[move.to].balls.append(moving)
        return next
    }

    /// `true` when the puzzle is solved: every tube is empty or a full single-color stack.
    public var isWon: Bool {
        tubes.allSatisfy { $0.isEmpty || $0.isComplete }
    }
}
