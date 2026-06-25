import Testing
@testable import BallSortCore

/// Tests for the reverse-move scrambling level generator (E3.2).
///
/// Solvability is guaranteed *by construction* (scrambling walks backwards along
/// legal forward moves from the solved state), so it is not asserted here via a
/// solver — that's a separate unit. These tests pin down the structural invariants
/// the generator must uphold: tube/capacity counts, ball-multiset conservation,
/// determinism under a fixed seed, and not-already-won for non-trivial depth.
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
            colors: 4, capacity: 4, emptyTubes: 2, scrambleDepth: 50, seed: 1
        )
        #expect(game.tubes.count == 6)
    }

    @Test("every tube has the requested capacity, and so does the state")
    func capacities() {
        let game = Generator().generate(
            colors: 3, capacity: 5, emptyTubes: 1, scrambleDepth: 30, seed: 7
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
            colors: colors, capacity: capacity, emptyTubes: 2, scrambleDepth: 80, seed: 42
        )
        let counts = multiset(game)
        let expectedColors = Array(BallColor.allCases.prefix(colors))
        #expect(Set(counts.keys) == Set(expectedColors))
        for color in expectedColors {
            #expect(counts[color] == capacity, "color \(color) should appear \(capacity) times")
        }
        // Total balls == colors * capacity.
        let total = counts.values.reduce(0, +)
        #expect(total == colors * capacity)
    }

    @Test("scrambling never overflows a tube past capacity")
    func noOverflow() {
        let capacity = 4
        let game = Generator().generate(
            colors: 5, capacity: capacity, emptyTubes: 2, scrambleDepth: 200, seed: 99
        )
        #expect(game.tubes.allSatisfy { $0.count <= capacity })
    }

    @Test("conservation holds across many seeds and configs")
    func conservationSweep() {
        for seed in UInt64(0)..<20 {
            let colors = 2 + Int(seed % 4)        // 2...5
            let capacity = 3 + Int(seed % 3)      // 3...5
            let emptyTubes = 1 + Int(seed % 2)    // 1...2
            let game = Generator().generate(
                colors: colors,
                capacity: capacity,
                emptyTubes: emptyTubes,
                scrambleDepth: 60,
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
            colors: 4, capacity: 4, emptyTubes: 2, scrambleDepth: 100, seed: 12345
        )
        let b = Generator().generate(
            colors: 4, capacity: 4, emptyTubes: 2, scrambleDepth: 100, seed: 12345
        )
        #expect(a == b)
    }

    @Test("different seeds generally produce different levels")
    func differentSeedsDiffer() {
        // Across a spread of seeds, at least one differs from seed 0 — a strong
        // signal the seed actually drives scrambling (not all-equal by accident).
        let base = Generator().generate(
            colors: 5, capacity: 4, emptyTubes: 2, scrambleDepth: 120, seed: 0
        )
        let anyDifferent = (UInt64(1)...30).contains { seed in
            Generator().generate(
                colors: 5, capacity: 4, emptyTubes: 2, scrambleDepth: 120, seed: seed
            ) != base
        }
        #expect(anyDifferent)
    }

    // MARK: - Solved start vs scrambled result

    @Test("zero scramble depth yields the solved (won) board")
    func zeroDepthIsWon() {
        let game = Generator().generate(
            colors: 4, capacity: 4, emptyTubes: 2, scrambleDepth: 0, seed: 1
        )
        #expect(game.isWon)
        // Solved board: `colors` complete single-color tubes + `emptyTubes` empty.
        let complete = game.tubes.filter { $0.isComplete }.count
        let empty = game.tubes.filter { $0.isEmpty }.count
        #expect(complete == 4)
        #expect(empty == 2)
    }

    @Test("a non-trivial scramble depth produces an unsolved board")
    func scrambledIsNotWon() {
        // With enough depth, several seeds must yield a non-won board; assert that
        // the generator can scramble away from the solved state.
        let anyUnsolved = (UInt64(0)..<20).contains { seed in
            !Generator().generate(
                colors: 4, capacity: 4, emptyTubes: 2, scrambleDepth: 100, seed: seed
            ).isWon
        }
        #expect(anyUnsolved)
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
            colors: 3, capacity: 4, emptyTubes: 1, scrambleDepth: 40, using: &rng
        )
        let viaSeed = Generator().generate(
            colors: 3, capacity: 4, emptyTubes: 1, scrambleDepth: 40, seed: 555
        )
        #expect(viaRNG == viaSeed)
    }
}
