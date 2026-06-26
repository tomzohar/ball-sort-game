import BallSortCore

/// The generator inputs for a single level. Mirrors `Generator.generate`'s
/// parameters so the composition can hand them straight through.
struct LevelParameters: Equatable, Sendable {
    var colors: Int
    var capacity: Int
    var emptyTubes: Int
    /// The difficulty floor in solver min-moves (the real difficulty lever).
    var minMoves: Int
}

/// Maps a 1-based level number onto the generator parameters for that level,
/// rising monotonically so the game gets harder as the player advances (E5.5).
///
/// Difficulty climbs on three fronts, each monotonic: more colors, fewer empty
/// tubes, and a higher min-moves floor. Colors are capped at the solver-feasible
/// ceiling (the generator verifies solvability, so deep palettes are out of reach).
struct DifficultyCurve: Equatable, Sendable {
    var baseColors: Int
    var maxColors: Int
    var colorsEveryLevels: Int
    var capacity: Int
    var baseEmptyTubes: Int
    var minEmptyTubes: Int
    var emptyDropEveryLevels: Int
    var baseMinMoves: Int
    var minMovesPerLevel: Int
    var maxMinMoves: Int

    /// Generator parameters for `level` (clamped to ≥ 1). Colors are non-decreasing,
    /// empty tubes non-increasing, and the min-moves floor non-decreasing — so the
    /// difficulty never drops as the player advances.
    func parameters(forLevel level: Int) -> LevelParameters {
        let lvl = max(1, level)
        let colors = min(maxColors, baseColors + (lvl - 1) / colorsEveryLevels)
        let empties = max(minEmptyTubes, baseEmptyTubes - (lvl - 1) / emptyDropEveryLevels)
        let minMoves = min(maxMinMoves, baseMinMoves + (lvl - 1) * minMovesPerLevel)
        return LevelParameters(
            colors: colors,
            capacity: capacity,
            emptyTubes: empties,
            minMoves: minMoves
        )
    }

    /// A coarse, solver-free difficulty label for `level`, used by the HUD badge so
    /// it always has a value instantly. The exact `DifficultyGrader` may refine it.
    /// Non-decreasing in `level`.
    func estimatedBand(forLevel level: Int) -> Difficulty.Band {
        switch max(1, level) {
        case ...2: return .easy
        case ...5: return .medium
        case ...8: return .hard
        default: return .expert
        }
    }

    /// The default rising curve. Starts gentle (4 colors, 2 empty tubes, a 10-move
    /// floor), grows to the 5-color solver-feasible ceiling, drops to a single empty
    /// tube past level 5, and raises the min-moves floor toward 24.
    static let `default` = DifficultyCurve(
        baseColors: 4,
        maxColors: 5,
        colorsEveryLevels: 2,
        capacity: 4,
        baseEmptyTubes: 2,
        minEmptyTubes: 1,
        emptyDropEveryLevels: 5,
        baseMinMoves: 10,
        minMovesPerLevel: 2,
        maxMinMoves: 24
    )
}
