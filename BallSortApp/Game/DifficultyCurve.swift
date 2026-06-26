import BallSortCore

/// The generator inputs for a single level. Mirrors `Generator.generate`'s
/// difficulty parameters so the composition can hand them straight through.
struct LevelParameters: Equatable, Sendable {
    var colors: Int
    var capacity: Int
    var emptyTubes: Int
    var scrambleDepth: Int
}

/// Maps a 1-based level number onto the generator parameters for that level,
/// rising monotonically so the game gets harder as the player advances (E5.5).
///
/// The curve is a pure, deterministic formula (no solver) — generation stays
/// cheap and solvable-by-construction. It also supplies a coarse `estimatedBand`
/// for the HUD badge, since running the BFS `DifficultyGrader` on deep boards is
/// too expensive to do synchronously at runtime.
struct DifficultyCurve: Equatable, Sendable {
    /// Colors at level 1.
    var baseColors: Int
    /// Palette ceiling — colors never exceed this (the available `BallColor` count).
    var maxColors: Int
    /// Add one color every this many levels.
    var colorsEveryLevels: Int
    var capacity: Int
    var emptyTubes: Int
    /// Reverse-scramble depth at level 1.
    var baseScramble: Int
    /// Extra scramble depth added per level — the primary difficulty lever.
    var scramblePerLevel: Int

    /// Generator parameters for `level` (clamped to ≥ 1). Scramble depth strictly
    /// increases with level and color count is non-decreasing, so difficulty never
    /// drops as the player advances.
    func parameters(forLevel level: Int) -> LevelParameters {
        let lvl = max(1, level)
        let colors = min(maxColors, baseColors + (lvl - 1) / colorsEveryLevels)
        let scramble = baseScramble + (lvl - 1) * scramblePerLevel
        return LevelParameters(
            colors: colors,
            capacity: capacity,
            emptyTubes: emptyTubes,
            scrambleDepth: scramble
        )
    }

    /// A coarse, solver-free difficulty label for `level`, used by the HUD badge so
    /// it always has a value instantly. The exact `DifficultyGrader` may refine it
    /// later for levels small enough to grade. Non-decreasing in `level`.
    func estimatedBand(forLevel level: Int) -> Difficulty.Band {
        switch max(1, level) {
        case ...2: return .easy
        case ...4: return .medium
        case ...7: return .hard
        default: return .expert
        }
    }

    /// The default rising curve. Level 1 matches E4's shipped board (5 colors,
    /// capacity 4, 2 empty tubes, 80 scramble); colors rise to the 6-color palette
    /// ceiling and scramble depth climbs 20 per level.
    static let `default` = DifficultyCurve(
        baseColors: 5,
        maxColors: BallColor.allCases.count,
        colorsEveryLevels: 3,
        capacity: 4,
        emptyTubes: 2,
        baseScramble: 80,
        scramblePerLevel: 20
    )
}
