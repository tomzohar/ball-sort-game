/// A graded difficulty: a coarse band plus the fine numeric score it was derived
/// from, so callers can both bucket a level and sort levels precisely on the curve.
///
/// `Comparable` orders by `score` (the fine signal); `band` is the coarse bucket
/// the score falls into. E5 uses the score to walk a rising difficulty curve and the
/// band to surface a human-facing label.
public struct Difficulty: Sendable, Equatable, Comparable {
    /// A coarse difficulty bucket. Ordered easiest → hardest by `RawValue`.
    public enum Band: Int, Sendable, Equatable, Comparable, CaseIterable {
        case trivial
        case easy
        case medium
        case hard
        case expert

        public static func < (lhs: Band, rhs: Band) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// The coarse bucket this level falls into.
    public let band: Band
    /// The fine numeric score the band was derived from. Higher means harder.
    public let score: Int

    public init(band: Band, score: Int) {
        self.band = band
        self.score = score
    }

    /// The hardest possible grading — also used as the verdict for an unsolvable state.
    public static let maximum = Difficulty(band: .expert, score: Int.max)

    public static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.score < rhs.score
    }
}

/// Grades a `GameState` into a `Difficulty` from three dimensions: distinct color
/// count, total tube count, and minimum-moves-to-solve.
///
/// Pure and `Sendable`. The solver is injected (`some Solving`) so tests can pin
/// min-moves with a fake — the grader never constructs its own `Solver`.
///
/// ## Scoring formula
///
/// ```
/// score = minMoves * 3 + tubeCount + colorCount
/// ```
///
/// Min-moves is the strongest signal (it captures the actual search depth a player
/// faces), so it carries the heaviest weight; color and tube counts are secondary
/// structural contributors. Because every weight is positive, the score is
/// **monotonic** in each dimension — increasing any one while holding the others
/// fixed never lowers it, and increasing min-moves *strictly* raises it. That is the
/// contract E5's rising curve relies on.
///
/// The score maps to a band by these thresholds (chosen against the prototype
/// reference points — Easy 4×4, Classic 5×5, Hard 6×6):
///
/// | score      | band     |
/// |------------|----------|
/// | `< 20`     | trivial  |
/// | `< 50`     | easy     |
/// | `< 90`     | medium   |
/// | `< 150`    | hard     |
/// | `>= 150`   | expert   |
///
/// ## Unsolvable states
///
/// The grader is meant for solvable, generator-produced levels. If the injected
/// solver returns `nil` (no solution), the grader does **not** trap; it returns
/// `Difficulty.maximum` — an unsolvable position is, in effect, infinitely hard.
public struct DifficultyGrader: Sendable {
    public init() {}

    private static let moveWeight = 3

    /// Grades `state` using `solver` to obtain its minimum-moves-to-solve.
    public func grade(_ state: GameState, using solver: some Solving) -> Difficulty {
        guard let solution = solver.solve(state) else {
            return .maximum
        }

        let minMoves = solution.count
        let tubeCount = state.tubes.count
        let colorCount = distinctColorCount(in: state)

        let score = minMoves * Self.moveWeight + tubeCount + colorCount
        return Difficulty(band: band(for: score), score: score)
    }

    /// The number of distinct ball colors present anywhere on the board.
    private func distinctColorCount(in state: GameState) -> Int {
        var colors: Set<BallColor> = []
        for tube in state.tubes {
            colors.formUnion(tube.balls)
        }
        return colors.count
    }

    private func band(for score: Int) -> Difficulty.Band {
        switch score {
        case ..<20: return .trivial
        case ..<50: return .easy
        case ..<90: return .medium
        case ..<150: return .hard
        default: return .expert
        }
    }
}
