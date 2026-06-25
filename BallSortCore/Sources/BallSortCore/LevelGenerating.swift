/// A source of fresh, guaranteed-solvable ball-sort levels.
///
/// Conformers emit a `GameState` whose solvability is guaranteed *by construction*
/// (e.g. reverse-move scrambling from the solved state) — no solver is consulted.
/// The randomness source is injected so generation is reproducible in tests: passing
/// the same seed (or the same deterministic `RandomNumberGenerator`) with the same
/// parameters always yields an identical level.
///
/// Injected into ViewModels via DI (see `docs/TECHNICAL_DECISIONS.md`); fakes can
/// conform for deterministic ViewModel tests.
public protocol LevelGenerating: Sendable {
    /// Generates a level by scrambling a solved board, driven by `generator`.
    ///
    /// - Parameters:
    ///   - colors: Number of distinct ball colors (one full tube each). Must be in
    ///     `1...BallColor.allCases.count`.
    ///   - capacity: Balls per tube; also the number of balls of each color. Must be `>= 1`.
    ///   - emptyTubes: Number of additional empty tubes. Must be `>= 1` (classic
    ///     ball-sort needs free space to be solvable).
    ///   - scrambleDepth: Number of inverse-move steps to apply. `0` returns the solved
    ///     board unchanged; larger values produce harder boards.
    ///   - generator: The randomness source, consumed in place.
    /// - Returns: A solvable, scrambled `GameState` with `colors + emptyTubes` tubes.
    func generate<R: RandomNumberGenerator>(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        scrambleDepth: Int,
        using generator: inout R
    ) -> GameState
}
