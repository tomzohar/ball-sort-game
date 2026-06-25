/// Generates guaranteed-solvable ball-sort levels by **reverse-move scrambling**.
///
/// The level starts solved — `colors` tubes each full of one distinct color, plus
/// `emptyTubes` empty tubes — and is then walked *backwards* along legal classic
/// moves. Each scramble step picks a legal forward move and applies its inverse, so
/// reversing the applied steps is always a valid solution: solvability is guaranteed
/// **by construction**, with no solver involved.
///
/// Scrambling preserves the ball multiset (it only relocates balls) and never
/// overflows a tube, so the structural invariants of the solved board are maintained.
public struct Generator: LevelGenerating, Sendable {
    public init() {}

    /// Generates a level by scrambling a solved board, driven by `generator`.
    ///
    /// See `LevelGenerating.generate` for the parameter contract. Inputs are validated
    /// with `precondition` — callers are expected to pass sane difficulty parameters.
    public func generate<R: RandomNumberGenerator>(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        scrambleDepth: Int,
        using generator: inout R
    ) -> GameState {
        precondition(colors >= 1, "a level needs at least one color")
        precondition(
            colors <= BallColor.allCases.count,
            "colors (\(colors)) exceeds the available palette (\(BallColor.allCases.count))"
        )
        precondition(capacity >= 1, "tube capacity must be at least 1")
        precondition(emptyTubes >= 1, "classic ball-sort needs at least one empty tube")
        precondition(scrambleDepth >= 0, "scramble depth cannot be negative")

        var state = solvedState(colors: colors, capacity: capacity, emptyTubes: emptyTubes)

        // Walk backwards along legal forward moves. Applying a legal forward move IS
        // an inverse scramble step from the solver's perspective; the picked moves,
        // reversed, form a valid solution — so the state stays solvable throughout.
        // Guard against immediately undoing the previous step to keep scrambling
        // making progress instead of churning on a single pair of tubes.
        var previous: Move?
        for _ in 0..<scrambleDepth {
            let candidates = state.legalMoves().filter { move in
                guard let previous else { return true }
                return !(move.from == previous.to && move.to == previous.from)
            }
            guard let move = candidates.randomElement(using: &generator) else { break }
            guard let next = state.apply(move) else { break }
            state = next
            previous = move
        }

        return state
    }

    /// Seeded convenience: deterministic generation from a `UInt64` seed.
    ///
    /// Same seed + same parameters always yields an identical level — used by tests.
    public func generate(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        scrambleDepth: Int,
        seed: UInt64
    ) -> GameState {
        var rng = SeededRandomNumberGenerator(seed: seed)
        return generate(
            colors: colors,
            capacity: capacity,
            emptyTubes: emptyTubes,
            scrambleDepth: scrambleDepth,
            using: &rng
        )
    }

    /// Production convenience: generation backed by the system RNG.
    public func generate(
        colors: Int,
        capacity: Int,
        emptyTubes: Int,
        scrambleDepth: Int
    ) -> GameState {
        var rng = SystemRandomNumberGenerator()
        return generate(
            colors: colors,
            capacity: capacity,
            emptyTubes: emptyTubes,
            scrambleDepth: scrambleDepth,
            using: &rng
        )
    }

    /// The solved board: `colors` full single-color tubes (a prefix of the palette)
    /// followed by `emptyTubes` empty tubes, every tube of the given `capacity`.
    private func solvedState(colors: Int, capacity: Int, emptyTubes: Int) -> GameState {
        let palette = Array(BallColor.allCases.prefix(colors))
        var tubes = palette.map { color in
            Tube(balls: Array(repeating: color, count: capacity), capacity: capacity)
        }
        tubes.append(
            contentsOf: (0..<emptyTubes).map { _ in Tube(balls: [], capacity: capacity) }
        )
        return GameState(tubes: tubes, capacity: capacity)
    }
}

/// A small, fast deterministic PRNG (SplitMix64) for reproducible level generation.
///
/// Conforms to `RandomNumberGenerator`, so it drops into any `randomElement(using:)`
/// or `.random(in:using:)` call. A given seed always produces the same sequence,
/// which is what makes seeded generation reproducible in tests.
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
