import Testing
@testable import BallSortCore

/// The solvability guarantee for epic E3: a seeded sweep over a matrix of generation
/// parameters proving that EVERY level the `Generator` produces is actually solvable by
/// the `Solver`, and that the solver's solution genuinely wins when replayed.
///
/// This is the true end-to-end check that generator and solver agree — the generator
/// guarantees solvability *by construction* (reverse-move scrambling), the solver finds
/// solutions *by search*, and this suite confirms the two never disagree.
///
/// Determinism: generation is driven by fixed `UInt64` seeds, so any failure is fully
/// reproducible from the seed + params reported in the assertion message.
///
/// Cost: BFS over `GameState.canonical` is finite but grows fast with board size, so the
/// matrix is deliberately capped at `colors <= 5` and `capacity <= 4` (see CLAUDE.md).
@Suite("Generator → Solver solvability sweep")
struct SolvabilityHarnessTests {
    /// One generation configuration in the sweep matrix.
    struct Params: CustomStringConvertible {
        let colors: Int
        let capacity: Int
        let emptyTubes: Int
        let scrambleDepth: Int

        var description: String {
            "colors=\(colors) capacity=\(capacity) emptyTubes=\(emptyTubes) "
                + "scrambleDepth=\(scrambleDepth)"
        }
    }

    /// The parameter matrix: realistic ranges kept small enough that BFS stays fast.
    ///
    /// colors 2…5 × capacity 3…4 × emptyTubes 1…2 × a spread of scramble depths.
    /// Each combo is then run across `seedCount` fixed seeds below.
    static let matrix: [Params] = {
        var params: [Params] = []
        for colors in 2...5 {
            for capacity in 3...4 {
                for emptyTubes in 1...2 {
                    for scrambleDepth in [10, 30, 60] {
                        params.append(
                            Params(
                                colors: colors,
                                capacity: capacity,
                                emptyTubes: emptyTubes,
                                scrambleDepth: scrambleDepth
                            )
                        )
                    }
                }
            }
        }
        return params
    }()

    /// Fixed seeds per param combo. 48 combos × 8 seeds = 384 generated levels, each
    /// generated, solved, and replayed — kept within the suite's time budget.
    static let seedCount: UInt64 = 8

    @Test("every generated level is solvable and its solution wins", arguments: matrix)
    func generatedLevelsAreSolvable(_ params: Params) throws {
        let generator = Generator()
        let solver = Solver()

        for seed in 0..<Self.seedCount {
            let context = "\(params) seed=\(seed)"

            let level = generator.generate(
                colors: params.colors,
                capacity: params.capacity,
                emptyTubes: params.emptyTubes,
                scrambleDepth: params.scrambleDepth,
                seed: seed
            )

            // Sanity: the generated board is structurally valid before we trust it.
            assertValidBoard(level, params: params, context: context)

            // 1. The solver finds a solution.
            let solution = try #require(
                solver.solve(level),
                "solver returned nil (no solution) for \(context)"
            )

            // 2. Replaying that solution from the level — every move legal in sequence —
            //    reaches a won state.
            var state = level
            for (index, move) in solution.enumerated() {
                let next = try #require(
                    state.apply(move),
                    "move #\(index) \(move) was illegal mid-solution for \(context)"
                )
                state = next
            }
            #expect(
                state.isWon,
                "solver's solution did not reach a won state for \(context)"
            )

            // An already-solved board (e.g. scrambleDepth that churned back) is fine, but
            // a non-empty solution must strictly transform the board, never no-op.
            if !level.isWon {
                #expect(
                    !solution.isEmpty,
                    "unsolved level got an empty solution for \(context)"
                )
            }
        }
    }

    // MARK: - Helpers

    /// Asserts `state` is a well-formed board for `params`: right tube count, every tube
    /// within capacity, and a ball multiset of exactly `capacity` balls per color over
    /// the first `colors` palette entries.
    private func assertValidBoard(_ state: GameState, params: Params, context: String) {
        #expect(
            state.tubes.count == params.colors + params.emptyTubes,
            "wrong tube count for \(context)"
        )
        #expect(state.capacity == params.capacity, "wrong board capacity for \(context)")

        for tube in state.tubes {
            #expect(tube.capacity == params.capacity, "tube capacity drifted for \(context)")
            #expect(tube.balls.count <= params.capacity, "tube over capacity for \(context)")
        }

        var counts: [BallColor: Int] = [:]
        for tube in state.tubes {
            for ball in tube.balls {
                counts[ball, default: 0] += 1
            }
        }
        let expected = Dictionary(
            uniqueKeysWithValues: BallColor.allCases.prefix(params.colors).map { ($0, params.capacity) }
        )
        #expect(counts == expected, "ball multiset != colors × capacity for \(context)")
    }
}
