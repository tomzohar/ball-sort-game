import Testing
@testable import BallSortCore

/// Tests for the random-fill + solver-verified level generator (E3.2).
///
/// The generator samples random boards and accepts only solver-verified, non-won
/// ones, tuned to a `minMoves` difficulty floor. These tests pin the structural
/// invariants (tube/capacity counts, ball-multiset conservation), determinism under
/// a fixed seed, the never-won / always-solvable guarantees, and that difficulty
/// actually responds to the `minMoves` floor.
@Suite("Generator")
struct GeneratorTests {
    /// A flat, order-independent multiset (color -> count) of every ball on the board.
    private func multiset(_ game: GameState) -> [BallColor: Int] {
        var counts: [BallColor: Int] = [:]
        for tube in game.tubes {
            for ball in tube.balls {
                counts[ball, default: 0] += 1
            }
        }
        return counts
    }

    // MARK: - Structure: tube & capacity counts

    @Test("tube count == colors + emptyTubes")
    func tubeCount() {
        let game = Generator().generate(
            colors: 4, capacity: 4, emptyTubes: 2, minMoves: 8, seed: 1
        )
        #expect(game.tubes.count == 6)
    }

    @Test("every tube has the requested capacity, and so does the state")
    func capacities() {
        let game = Generator().generate(
            colors: 3, capacity: 5, emptyTubes: 1, minMoves: 6, seed: 7
        )
        #expect(game.capacity == 5)
        #expect(game.tubes.allSatisfy { $0.capacity == 5 })
    }

    // MARK: - Conservation: ball multiset

    @Test("ball multiset is exactly `capacity` of each of the `colors` colors")
    func ballMultiset() {
        let colors = 4
        let capacity = 4
        let game = Generator().generate(
            colors: colors, capacity: capacity, emptyTubes: 2, minMoves: 10, seed: 42
        )
        let counts = multiset(game)
        let expectedColors = Array(BallColor.allCases.prefix(colors))
        #expect(Set(counts.keys) == Set(expectedColors))
        for color in expectedColors {
            #expect(counts[color] == capacity, "color \(color) should appear \(capacity) times")
        }
        let total = counts.values.reduce(0, +)
        #expect(total == colors * capacity)
    }

    @Test("filling never overflows a tube past capacity")
    func noOverflow() {
        let capacity = 4
        let game = Generator().generate(
            colors: 5, capacity: capacity, emptyTubes: 2, minMoves: 12, seed: 99
        )
        #expect(game.tubes.allSatisfy { $0.count <= capacity })
    }

    @Test("conservation holds across many seeds and configs")
    func conservationSweep() {
        for seed in UInt64(0)..<20 {
            let colors = 2 + Int(seed % 4)        // 2...5
            let capacity = 3 + Int(seed % 2)      // 3...4
            let emptyTubes = 1 + Int(seed % 2)    // 1...2
            let game = Generator().generate(
                colors: colors,
                capacity: capacity,
                emptyTubes: emptyTubes,
                minMoves: 5,
                seed: seed
            )
            #expect(game.tubes.count == colors + emptyTubes)
            #expect(game.tubes.allSatisfy { $0.capacity == capacity })
            let counts = multiset(game)
            #expect(counts.values.reduce(0, +) == colors * capacity)
            #expect(counts.values.allSatisfy { $0 == capacity })
        }
    }

    // MARK: - Determinism

    @Test("same seed + same params => identical GameState")
    func deterministicSameSeed() {
        let a = Generator().generate(
            colors: 4, capacity: 4, emptyTubes: 2, minMoves: 10, seed: 12345
        )
        let b = Generator().generate(
            colors: 4, capacity: 4, emptyTubes: 2, minMoves: 10, seed: 12345
        )
        #expect(a == b)
    }

    @Test("different seeds generally produce different levels")
    func differentSeedsDiffer() {
        let base = Generator().generate(
            colors: 5, capacity: 4, emptyTubes: 2, minMoves: 10, seed: 0
        )
        let anyDifferent = (UInt64(1)...30).contains { seed in
            Generator().generate(
                colors: 5, capacity: 4, emptyTubes: 2, minMoves: 10, seed: seed
            ) != base
        }
        #expect(anyDifferent)
    }

    // MARK: - Always solvable, never won

    @Test("generated boards are never already won")
    func neverWon() {
        for seed in UInt64(0)..<24 {
            let colors = 2 + Int(seed % 4)
            let game = Generator().generate(
                colors: colors, capacity: 4, emptyTubes: 2, minMoves: 1, seed: seed
            )
            #expect(!game.isWon, "seed \(seed) produced an already-won board")
        }
    }

    @Test("generated boards are solver-verified solvable")
    func alwaysSolvable() {
        let solver = Solver()
        for seed in UInt64(0)..<16 {
            let game = Generator().generate(
                colors: 4, capacity: 4, emptyTubes: 2, minMoves: 8, seed: seed
            )
            #expect(solver.solve(game) != nil, "seed \(seed) produced an unsolvable board")
        }
    }

    // MARK: - Difficulty floor

    @Test("result meets the minMoves difficulty floor when achievable")
    func meetsDifficultyFloor() {
        let solver = Solver()
        let floor = 12
        for seed in UInt64(0)..<8 {
            let game = Generator().generate(
                colors: 5, capacity: 4, emptyTubes: 2, minMoves: floor, seed: seed
            )
            let moves = solver.solve(game)?.count ?? -1
            #expect(moves >= floor, "seed \(seed): min-moves \(moves) below floor \(floor)")
        }
    }

    // MARK: - PRNG determinism (unit on the seeded RNG itself)

    @Test("SeededRandomNumberGenerator is deterministic for a given seed")
    func prngDeterministic() {
        var a = SeededRandomNumberGenerator(seed: 0xDEAD_BEEF)
        var b = SeededRandomNumberGenerator(seed: 0xDEAD_BEEF)
        let seqA = (0..<16).map { _ in a.next() }
        let seqB = (0..<16).map { _ in b.next() }
        #expect(seqA == seqB)
    }

    @Test("SeededRandomNumberGenerator differs across seeds")
    func prngSeedsDiffer() {
        var a = SeededRandomNumberGenerator(seed: 1)
        var b = SeededRandomNumberGenerator(seed: 2)
        #expect(a.next() != b.next())
    }

    // MARK: - Generic RNG entry point

    @Test("generic inout RNG entry point matches the seed convenience")
    func genericRNGMatchesSeedConvenience() {
        var rng = SeededRandomNumberGenerator(seed: 555)
        let viaRNG = Generator().generate(
            colors: 3, capacity: 4, emptyTubes: 1, minMoves: 6, using: &rng
        )
        let viaSeed = Generator().generate(
            colors: 3, capacity: 4, emptyTubes: 1, minMoves: 6, seed: 555
        )
        #expect(viaRNG == viaSeed)
    }
}
