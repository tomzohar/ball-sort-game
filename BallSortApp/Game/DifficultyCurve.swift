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
/// Difficulty climbs on four fronts, each monotonic: more colors, fewer empty tubes,
/// a higher min-moves floor, and — deep in the curve — taller tubes (more capacity).
/// Colors are capped at the solver-feasible ceiling (the generator verifies
/// solvability, so deep palettes are out of reach).
///
/// **Why capacity is the deep-game lever (E14.1).** Once colors, empty tubes, and the
/// min-moves floor top out (~level 8 under the old curve), difficulty used to flatline.
/// Growing tube capacity reopens it — but only safely *after* the curve has dropped to
/// a single empty tube. Generation runs the solver up to 80×, and solver cost explodes
/// with empty-tube count (the branching factor), not board size: at one empty tube a
/// 5-colour×6-capacity board grades ~164 yet generates sub-second, whereas the same
/// board with two empty tubes takes ~80s. So capacity only steps up at/after
/// `capacityStartLevel`, which must sit at or past the empty-tube floor.
struct DifficultyCurve: Equatable, Sendable {
    var baseColors: Int
    var maxColors: Int
    var colorsEveryLevels: Int
    var baseCapacity: Int
    var maxCapacity: Int
    /// Capacity stays at `baseCapacity` until this level, then steps up. Keep it at or
    /// past the level where empty tubes bottom out, or generation gets pathologically slow.
    var capacityStartLevel: Int
    var capacityEveryLevels: Int
    var baseEmptyTubes: Int
    var minEmptyTubes: Int
    var emptyDropEveryLevels: Int
    var baseMinMoves: Int
    var minMovesPerLevel: Int
    var maxMinMoves: Int

    /// - Parameters default capacity growth to *off* (`maxCapacity == baseCapacity`,
    ///   start at `.max`) so callers that don't care about it get a constant capacity.
    init(
        baseColors: Int,
        maxColors: Int,
        colorsEveryLevels: Int,
        baseCapacity: Int,
        maxCapacity: Int? = nil,
        capacityStartLevel: Int = .max,
        capacityEveryLevels: Int = 1,
        baseEmptyTubes: Int,
        minEmptyTubes: Int,
        emptyDropEveryLevels: Int,
        baseMinMoves: Int,
        minMovesPerLevel: Int,
        maxMinMoves: Int
    ) {
        self.baseColors = baseColors
        self.maxColors = maxColors
        self.colorsEveryLevels = colorsEveryLevels
        self.baseCapacity = baseCapacity
        self.maxCapacity = max(baseCapacity, maxCapacity ?? baseCapacity)
        self.capacityStartLevel = capacityStartLevel
        self.capacityEveryLevels = max(1, capacityEveryLevels)
        self.baseEmptyTubes = baseEmptyTubes
        self.minEmptyTubes = minEmptyTubes
        self.emptyDropEveryLevels = emptyDropEveryLevels
        self.baseMinMoves = baseMinMoves
        self.minMovesPerLevel = minMovesPerLevel
        self.maxMinMoves = maxMinMoves
    }

    /// Generator parameters for `level` (clamped to ≥ 1). Colors are non-decreasing,
    /// empty tubes non-increasing, capacity non-decreasing, and the min-moves floor
    /// non-decreasing — so the difficulty never drops as the player advances.
    func parameters(forLevel level: Int) -> LevelParameters {
        let lvl = max(1, level)
        let colors = min(maxColors, baseColors + (lvl - 1) / colorsEveryLevels)
        let empties = max(minEmptyTubes, baseEmptyTubes - (lvl - 1) / emptyDropEveryLevels)
        let minMoves = min(maxMinMoves, baseMinMoves + (lvl - 1) * minMovesPerLevel)
        let capacity = min(maxCapacity, baseCapacity + max(0, lvl - capacityStartLevel) / capacityEveryLevels)
        return LevelParameters(
            colors: colors,
            capacity: capacity,
            emptyTubes: empties,
            minMoves: minMoves
        )
    }

    /// A coarse, solver-free difficulty label for `level`, used by the HUD badge so
    /// it always has a value instantly. The exact `DifficultyGrader` may refine it.
    /// Non-decreasing in `level`; tracks the curve's milestones — colours top out by
    /// ~level 6, capacity then climbs through the teens to the expert ceiling.
    func estimatedBand(forLevel level: Int) -> Difficulty.Band {
        switch max(1, level) {
        case ...2: return .easy
        case ...6: return .medium
        case ...15: return .hard
        default: return .expert
        }
    }

    /// The default rising curve. Starts gentle (4 colors, 4-ball tubes, 2 empty tubes,
    /// a 10-move floor) and climbs on four fronts: colors to the 5-color solver ceiling
    /// (by level 3), empty tubes down to one (by level 6), the min-moves floor toward 48,
    /// and — once a single empty tube keeps generation fast — tube capacity from 4 up to
    /// 6 (level 11 → 5, level 16 → 6). Capacity growth starts at level 6 so it never
    /// overlaps the two-empty-tube band, where the solver is far too slow (E14.1).
    static let `default` = DifficultyCurve(
        baseColors: 4,
        maxColors: 5,
        colorsEveryLevels: 2,
        baseCapacity: 4,
        maxCapacity: 6,
        capacityStartLevel: 6,
        capacityEveryLevels: 5,
        baseEmptyTubes: 2,
        minEmptyTubes: 1,
        emptyDropEveryLevels: 5,
        baseMinMoves: 10,
        minMovesPerLevel: 2,
        maxMinMoves: 48
    )
}
