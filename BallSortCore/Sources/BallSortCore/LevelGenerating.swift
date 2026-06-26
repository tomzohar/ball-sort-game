/// A source of fresh, guaranteed-solvable ball-sort levels at a target difficulty.
///
/// Conformers emit a `GameState` that is **verified solvable** and tuned to a
/// minimum solving difficulty (measured in solver min-moves). The randomness source
/// is injected so generation is reproducible in tests: passing the same seed (or the
/// same deterministic `RandomNumberGenerator`) with the same parameters always
/// yields an identical level.
///
/// Injected into ViewModels via DI (see `docs/TECHNICAL_DECISIONS.md`); fakes can
/// conform for deterministic ViewModel tests.
public protocol LevelGenerating: Sendable {
    /// Generates a solvable, non-won level at (at least) the requested difficulty.
    ///
    /// - Parameters:
    ///   - colors: Number of distinct ball colors (one full tube each). Must be in
    ///     `1...BallColor.allCases.count`.
    ///   - capacity: Balls per tube; also the number of balls of each color. Must be `>= 1`.
    ///   - emptyTubes: Number of additional empty tubes. Must be `>= 1` (classic
    ///     ball-sort needs free space to be solvable).
    ///   - minMoves: The desired difficulty floor, in shortest-solution moves. The
    ///     generator returns the first sampled level meeting this floor, or — if the
    ///     floor isn't reached within its attempt budget — the hardest solvable level
    ///     it found. Must be `>= 0`.
    ///   - generator: The randomness source, consumed in place.
    /// - Returns: A solvable, non-won `GameState` with `colors + emptyTubes` tubes.
    func generate<R: RandomNumberGenerator>(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        minMoves: Int,
        using generator: inout R
    ) -> GameState
}
