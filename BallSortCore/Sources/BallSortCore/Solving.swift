/// A capability that finds a solution to a ball-sort position.
///
/// Injected into ViewModels as a protocol (DI) so the concrete `Solver` can be
/// swapped for a fake in tests. Implementations must return a *shortest* move
/// sequence — difficulty grading (E3.4) keys off MIN-MOVES, and hints (E6) lean
/// on the next move of an optimal solution.
public protocol Solving: Sendable {
    /// A shortest sequence of legal moves that wins `state`, `[]` if it is already
    /// won, or `nil` if the position is unsolvable.
    func solve(_ state: GameState) -> [Move]?
}

extension Solving {
    /// Whether `state` can be solved at all. Defaults to `solve(state) != nil`.
    public func isSolvable(_ state: GameState) -> Bool {
        solve(state) != nil
    }
}
