/// Generates guaranteed-solvable ball-sort levels by **random fill + solver
/// verification** (rejection sampling).
///
/// A candidate board is produced by shuffling the exact ball multiset (`capacity`
/// of each of `colors` colors) across the color tubes, leaving `emptyTubes` empty.
/// The candidate is then checked with the injected `Solving`: only **solvable,
/// non-won** boards are eligible, and the generator keeps sampling until it finds
/// one meeting the requested `minMoves` difficulty floor (or returns the hardest it
/// found within its attempt budget).
///
/// This replaces the earlier reverse-move scramble, which — though solvable by
/// construction — equilibrated near the solved state and produced trivial (~2-move)
/// levels regardless of depth. Verifying solvability directly lets difficulty be
/// driven by the actual solver min-moves, which is what a rising curve needs.
///
/// Determinism: the shuffle is the only randomness, so a given seed + parameters
/// always yields the same level. Because verification runs the solver, generation
/// is bounded to solver-feasible board sizes (small color counts / capacities).
public struct Generator: LevelGenerating, Sendable {
    private let solver: any Solving
    private let maxAttempts: Int

    /// - Parameters:
    ///   - solver: Used to verify candidate solvability and measure difficulty.
    ///   - maxAttempts: How many random fills to sample before giving up on the
    ///     `minMoves` floor and returning the hardest solvable board found.
    public init(solver: some Solving = Solver(), maxAttempts: Int = 80) {
        precondition(maxAttempts >= 1, "need at least one sampling attempt")
        self.solver = solver
        self.maxAttempts = maxAttempts
    }

    public func generate<R: RandomNumberGenerator>(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        minMoves: Int,
        using generator: inout R
    ) -> GameState {
        precondition(colors >= 1, "a level needs at least one color")
        precondition(
            colors <= BallColor.allCases.count,
            "colors (\(colors)) exceeds the available palette (\(BallColor.allCases.count))"
        )
        precondition(capacity >= 1, "tube capacity must be at least 1")
        precondition(emptyTubes >= 1, "classic ball-sort needs at least one empty tube")
        precondition(minMoves >= 0, "minMoves cannot be negative")

        var best: GameState?
        var bestMoves = -1

        for _ in 0..<maxAttempts {
            let candidate = randomFill(
                colors: colors, capacity: capacity, emptyTubes: emptyTubes, using: &generator
            )
            if candidate.isWon { continue }
            guard let solution = solver.solve(candidate) else { continue } // unsolvable fill

            let moves = solution.count
            if moves >= minMoves { return candidate } // meets the difficulty floor
            if moves > bestMoves {
                bestMoves = moves
                best = candidate
            }
        }

        if let best { return best }

        // Vanishingly unlikely (every sample was won or unsolvable): keep sampling
        // for a solvable non-won board, then fall back to a one-move-off-solved board
        // (always solvable) so generation always terminates with a valid level.
        for _ in 0..<(maxAttempts * 4) {
            let candidate = randomFill(
                colors: colors, capacity: capacity, emptyTubes: emptyTubes, using: &generator
            )
            if !candidate.isWon, solver.isSolvable(candidate) { return candidate }
        }
        return oneMoveOffSolved(colors: colors, capacity: capacity, emptyTubes: emptyTubes)
    }

    /// Seeded convenience: deterministic generation from a `UInt64` seed.
    public func generate(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        minMoves: Int,
        seed: UInt64
    ) -> GameState {
        var rng = SeededRandomNumberGenerator(seed: seed)
        return generate(
            colors: colors, capacity: capacity, emptyTubes: emptyTubes, minMoves: minMoves, using: &rng
        )
    }

    /// Production convenience: generation backed by the system RNG.
    public func generate(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        minMoves: Int
    ) -> GameState {
        var rng = SystemRandomNumberGenerator()
        return generate(
            colors: colors, capacity: capacity, emptyTubes: emptyTubes, minMoves: minMoves, using: &rng
        )
    }

    /// A random board: the exact ball multiset shuffled across `colors` full tubes,
    /// followed by `emptyTubes` empty tubes. Conserves the multiset and never
    /// overflows a tube (each color tube gets exactly `capacity` balls).
    private func randomFill<R: RandomNumberGenerator>(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        using generator: inout R
    ) -> GameState {
        let palette = Array(BallColor.allCases.prefix(colors))
        var balls: [BallColor] = []
        balls.reserveCapacity(colors * capacity)
        for color in palette {
            balls.append(contentsOf: repeatElement(color, count: capacity))
        }
        balls.shuffle(using: &generator)

        var tubes: [Tube] = []
        tubes.reserveCapacity(colors + emptyTubes)
        for index in 0..<colors {
            let slice = Array(balls[(index * capacity)..<((index + 1) * capacity)])
            tubes.append(Tube(balls: slice, capacity: capacity))
        }
        tubes.append(
            contentsOf: (0..<emptyTubes).map { _ in Tube(balls: [], capacity: capacity) }
        )
        return GameState(tubes: tubes, capacity: capacity)
    }

    /// The solved board with a single ball lifted into an empty tube — always
    /// solvable (reverse the one move) and never won. Last-resort fallback only.
    private func oneMoveOffSolved(colors: Int, capacity: Int, emptyTubes: Int) -> GameState {
        let palette = Array(BallColor.allCases.prefix(colors))
        var tubes = palette.map { color in
            Tube(balls: Array(repeating: color, count: capacity), capacity: capacity)
        }
        tubes.append(
            contentsOf: (0..<emptyTubes).map { _ in Tube(balls: [], capacity: capacity) }
        )
        var state = GameState(tubes: tubes, capacity: capacity)
        // Move the top ball of the first color tube into the first empty tube.
        if let moved = state.apply(Move(from: 0, to: colors)) {
            state = moved
        }
        return state
    }
}

/// A small, fast deterministic PRNG (SplitMix64) for reproducible level generation.
///
/// Conforms to `RandomNumberGenerator`, so it drops into any `shuffle(using:)` or
/// `.random(in:using:)` call. A given seed always produces the same sequence, which
/// is what makes seeded generation reproducible in tests.
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    /// Creates a generator seeded with `seed`. Equal seeds yield equal sequences.
    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        // SplitMix64: a well-distributed, full-period 64-bit mixer.
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
