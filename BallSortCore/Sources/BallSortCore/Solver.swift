/// A breadth-first ball-sort solver.
///
/// `solve` explores game states layer by layer, so the first winning state it
/// reaches is at minimum depth — the returned move sequence is guaranteed
/// *shortest*. The visited set is keyed on `GameState.canonical`, which collapses
/// tube permutations to a single representative; without it BFS would re-expand
/// the same position once per permutation and blow up. The finite, dedup'd state
/// space guarantees termination with no depth cap.
public struct Solver: Solving, Sendable {
    public init() {}

    /// A shortest legal move sequence that wins `state`, `[]` if already won, or
    /// `nil` if no solution exists.
    ///
    /// BFS from `state`: each dequeued node expands into its `legalMoves`, and
    /// every resulting state not yet seen (by canonical form) is enqueued with the
    /// path that produced it. The first `isWon` state dequeued yields the answer.
    public func solve(_ state: GameState) -> [Move]? {
        if state.isWon { return [] }

        var visited: Set<GameState> = [state.canonical]
        var queue: [(state: GameState, path: [Move])] = [(state, [])]
        var head = 0

        while head < queue.count {
            let (current, path) = queue[head]
            head += 1

            for move in current.legalMoves() {
                guard let next = current.apply(move) else { continue }
                let key = next.canonical
                guard visited.insert(key).inserted else { continue }

                let nextPath = path + [move]
                if next.isWon { return nextPath }
                queue.append((next, nextPath))
            }
        }

        return nil
    }
}
