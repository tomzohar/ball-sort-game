/// Search-key canonicalization for the solver.
///
/// Two states that differ only by how their tubes are *permuted* are the same
/// puzzle position — a solver must treat them as one node, or it will re-expand
/// the same position once per permutation and blow up. `canonical` collapses every
/// permutation of a position to a single representative by sorting the tubes into a
/// deterministic, stable order. The synthesized `Hashable`/`Equatable` on `GameState`
/// then makes permutation-symmetric states hash and compare equal *after*
/// canonicalization, which is exactly the dedup key BFS/A* needs for its visited set.
extension GameState {
    /// An equivalent state whose `tubes` are sorted into a deterministic, stable order.
    ///
    /// States that differ only by a permutation of their tubes canonicalize to the
    /// **same** value, so `a.canonical == b.canonical` (and `a.canonical.hashValue ==
    /// b.canonical.hashValue`) iff `a` and `b` are the same position up to tube order.
    /// Use `canonical` — together with `GameState`'s synthesized `Hashable`/`Equatable`
    /// — as the dedup key for the visited-state set in BFS/A* search.
    ///
    /// Tubes are ordered by a total order on their contents: `balls` compared
    /// lexicographically by `BallColor.rawValue`, with shorter stacks ordering before
    /// longer ones on a shared prefix, then by `capacity` as a final tie-breaker. Empty
    /// tubes (empty `balls`) sort consistently together at the front. Pure: `self` is
    /// never mutated; `capacity` and the ball multiset are preserved, and so is `isWon`.
    public var canonical: GameState {
        var copy = self
        copy.tubes.sort(by: GameState.tubeOrdersBefore)
        return copy
    }

    /// A strict total order over tubes: lexicographic by ball `rawValue`, then by capacity.
    private static func tubeOrdersBefore(_ lhs: Tube, _ rhs: Tube) -> Bool {
        let count = min(lhs.balls.count, rhs.balls.count)
        for index in 0..<count {
            let left = lhs.balls[index].rawValue
            let right = rhs.balls[index].rawValue
            if left != right { return left < right }
        }
        if lhs.balls.count != rhs.balls.count {
            return lhs.balls.count < rhs.balls.count
        }
        return lhs.capacity < rhs.capacity
    }
}
