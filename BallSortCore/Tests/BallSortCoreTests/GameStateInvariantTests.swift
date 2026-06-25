import Testing
@testable import BallSortCore

/// Property-style sweep: invariants that must hold across the whole domain core,
/// driven over a handful of hand-built representative states × all their legal moves.
@Suite("GameState invariants")
struct GameStateInvariantTests {
    private func state(_ tubes: [[BallColor]], capacity: Int = 4) -> GameState {
        GameState(tubes: tubes.map { Tube(balls: $0, capacity: capacity) }, capacity: capacity)
    }

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

    /// A representative spread of small, hand-built states: empty, partial, full,
    /// mixed, solved, and a few multi-tube boards with several legal moves available.
    private var representativeStates: [GameState] {
        [
            state([[], []]),
            state([[.yellow], []]),
            state([[.blue], [.blue]]),
            state([[.blue], [.green], []]),
            state([[.yellow, .blue], [.blue]]),
            state([[.yellow, .blue], []]),
            state([[.blue, .green], [.green, .blue], []]),
            state([[.purple], [.purple, .purple]], capacity: 4),
            state([[], [.blue, .blue, .blue, .blue], [.green, .green, .green, .green]]),
            state([[.blue, .green, .blue, .green]]),
            state([[.yellow, .orange, .pink], [.pink, .orange, .yellow], [.green], []]),
            state([[.blue, .blue, .blue], [.blue], [.green, .green], [.green, .green], []])
        ]
    }

    // MARK: - Ball-multiset conservation

    @Test("apply preserves the ball multiset for every legal move on every state")
    func applyConservesMultiset() {
        for game in representativeStates {
            let before = multiset(game)
            for move in game.legalMoves() {
                let next = try? #require(game.apply(move))
                guard let next else { continue }
                #expect(multiset(next) == before, "move \(move) changed the ball multiset")
            }
        }
    }

    // MARK: - Legality <=> apply

    @Test("apply(m) != nil iff isLegal(m), swept over the full index grid")
    func applyAgreesWithLegality() {
        for game in representativeStates {
            let count = game.tubes.count
            // Sweep a grid slightly wider than the board to include out-of-bounds moves.
            for from in -1...count {
                for to in -1...count {
                    let move = Move(from: from, to: to)
                    #expect(
                        (game.apply(move) != nil) == game.isLegal(move),
                        "apply/isLegal disagree on \(move)"
                    )
                }
            }
        }
    }

    @Test("legalMoves returns only moves that isLegal accepts")
    func legalMovesAreAllLegal() {
        for game in representativeStates {
            for move in game.legalMoves() {
                #expect(game.isLegal(move))
            }
        }
    }

    @Test("an illegal move always yields nil")
    func illegalMoveYieldsNil() {
        for game in representativeStates {
            let count = game.tubes.count
            for from in -1...count {
                for to in -1...count {
                    let move = Move(from: from, to: to)
                    if !game.isLegal(move) {
                        #expect(game.apply(move) == nil)
                    }
                }
            }
        }
    }

    // MARK: - Win soundness

    @Test("isWon is true exactly when every tube is empty or full-single-color")
    func isWonMatchesDefinition() {
        for game in representativeStates {
            let expected = game.tubes.allSatisfy { tube in
                tube.isEmpty || (tube.isFull && Set(tube.balls).count == 1)
            }
            #expect(game.isWon == expected)
        }
    }

    @Test("a state with any mixed or partial non-empty tube is not won")
    func mixedOrPartialIsNotWon() {
        // Partial single-color tube (not full) -> not won.
        #expect(!state([[.blue, .blue], []]).isWon)
        // Full but mixed -> not won.
        #expect(!state([[.blue, .green, .blue, .green]]).isWon)
        // Mixed partial -> not won.
        #expect(!state([[.blue, .green]]).isWon)
    }

    // MARK: - Canonical

    @Test("canonical is idempotent")
    func canonicalIdempotent() {
        for game in representativeStates {
            #expect(game.canonical.canonical == game.canonical)
        }
    }

    @Test("permuted copies share canonical and hashValue")
    func permutationsShareCanonical() {
        for game in representativeStates {
            for permuted in permutations(of: game) {
                #expect(permuted.canonical == game.canonical)
                #expect(permuted.canonical.hashValue == game.canonical.hashValue)
            }
        }
    }

    @Test("canonicalization preserves the ball multiset")
    func canonicalPreservesMultiset() {
        for game in representativeStates {
            #expect(multiset(game.canonical) == multiset(game))
        }
    }

    @Test("canonicalization preserves isWon")
    func canonicalPreservesIsWon() {
        for game in representativeStates {
            #expect(game.canonical.isWon == game.isWon)
        }
    }

    @Test("canonical does not mutate self")
    func canonicalIsPure() {
        for game in representativeStates {
            let before = game
            _ = game.canonical
            #expect(game == before)
        }
    }

    // MARK: - Helpers

    /// A few tube permutations of `game` (capped) to exercise canonicalization.
    private func permutations(of game: GameState) -> [GameState] {
        let indices = Array(game.tubes.indices)
        guard indices.count > 1 else { return [game] }
        var results: [GameState] = []
        // Reversed order.
        var reversed = game
        reversed.tubes = game.tubes.reversed()
        results.append(reversed)
        // Single adjacent swaps across the board.
        for i in 0..<(indices.count - 1) {
            var swapped = game
            swapped.tubes.swapAt(i, i + 1)
            results.append(swapped)
        }
        // Left rotation by one.
        if indices.count > 2 {
            var rotated = game
            let first = rotated.tubes.removeFirst()
            rotated.tubes.append(first)
            results.append(rotated)
        }
        return results
    }
}
