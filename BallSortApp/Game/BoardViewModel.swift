import Foundation
import Observation
import BallSortCore

/// Drives the full single-level → next-level gameplay loop as an `@Observable`
/// state machine (E5). Move legality and application are delegated entirely to
/// `BallSortCore` (classic ball-sort rule); this view model owns the surrounding
/// loop: selection, move count, undo history, an elapsed-time clock, sorted-tube
/// count, win detection, and generator-driven level advancement along a rising
/// `DifficultyCurve`.
///
/// Dependencies (generator / solver / grader / curve / clock) are injected with
/// production defaults so the composition root can build it with `BoardViewModel()`
/// and tests can pin a board (`init(initialState:)`) or fakes.
@MainActor
@Observable
final class BoardViewModel {
    /// The current board snapshot.
    private(set) var gameState: GameState

    /// The lifted source tube awaiting a destination, or `nil` when nothing is
    /// selected.
    private(set) var selectedTube: Int?

    /// The number of net moves applied on the current level (undo decrements it).
    private(set) var moveCount: Int

    /// The destination tube of the most recent successful move — drives the
    /// drop animation — or `nil` when the last interaction wasn't a move.
    private(set) var lastDrop: Int?

    /// The 1-based level the player is on.
    private(set) var level: Int

    /// The exact difficulty grade once computed for small-enough levels, else `nil`.
    /// Prefer `difficultyBand` for display — it always has a value.
    private(set) var difficulty: Difficulty?

    /// The state `restart()` resets to — the current level's starting board.
    private var initialState: GameState

    /// Snapshots taken before each applied move, newest last; powers `undo()`.
    private var history: [GameState] = []

    // MARK: - Injected dependencies

    private let generator: (any LevelGenerating)?
    private let solver: any Solving
    private let grader: DifficultyGrader
    private let curve: DifficultyCurve
    private let seed: UInt64?
    private let now: () -> TimeInterval

    // MARK: - Timer

    private var startedAt: TimeInterval?
    private var frozenElapsed: TimeInterval = 0

    /// Exact BFS grading is only attempted within these known-feasible bounds
    /// (the E3 solvability-harness limits); deeper/wider boards would make the
    /// solver search blow up, so the badge falls back to the curve estimate.
    private static let maxGradableColors = 5
    private static let maxGradableScramble = 60

    /// The in-flight grading task, exposed for deterministic test awaiting.
    @ObservationIgnored private(set) var gradingTask: Task<Void, Never>?

    // MARK: - Designated init

    private init(
        state: GameState,
        generator: (any LevelGenerating)?,
        solver: any Solving,
        grader: DifficultyGrader,
        curve: DifficultyCurve,
        level: Int,
        seed: UInt64?,
        now: @escaping () -> TimeInterval
    ) {
        self.gameState = state
        self.initialState = state
        self.selectedTube = nil
        self.moveCount = 0
        self.lastDrop = nil
        self.level = max(1, level)
        self.generator = generator
        self.solver = solver
        self.grader = grader
        self.curve = curve
        self.seed = seed
        self.now = now
    }

    /// Pins a fixed board with progression disabled — for tests and snapshots.
    convenience init(initialState: GameState) {
        self.init(
            state: initialState,
            generator: nil,
            solver: Solver(),
            grader: DifficultyGrader(),
            curve: .default,
            level: 1,
            seed: nil,
            now: { Date().timeIntervalSinceReferenceDate }
        )
        startTimer()
    }

    /// Pins a fixed board with an injectable clock — for deterministic timer tests.
    convenience init(initialState: GameState, now: @escaping () -> TimeInterval) {
        self.init(
            state: initialState,
            generator: nil,
            solver: Solver(),
            grader: DifficultyGrader(),
            curve: .default,
            level: 1,
            seed: nil,
            now: now
        )
        startTimer()
    }

    /// The production game loop: generates `startingLevel` from `curve` and begins
    /// the difficulty progression. A non-`nil` `seed` makes the whole run
    /// reproducible (per-level seeds are derived from it).
    convenience init(
        generator: some LevelGenerating = Generator(),
        solver: some Solving = Solver(),
        grader: DifficultyGrader = DifficultyGrader(),
        curve: DifficultyCurve = .default,
        startingLevel: Int = 1,
        seed: UInt64? = nil,
        now: @escaping () -> TimeInterval = { Date().timeIntervalSinceReferenceDate }
    ) {
        let lvl = max(1, startingLevel)
        let state = Self.makeLevel(
            forLevel: lvl, generator: generator, curve: curve, seed: seed
        )
        self.init(
            state: state,
            generator: generator,
            solver: solver,
            grader: grader,
            curve: curve,
            level: lvl,
            seed: seed,
            now: now
        )
        startTimer()
        scheduleGrading()
    }

    // MARK: - Derived state

    /// `true` once every tube is empty or a finished single-color stack.
    var isWon: Bool { gameState.isWon }

    /// Whether `index` is the currently lifted source tube.
    func isSelected(_ index: Int) -> Bool { selectedTube == index }

    /// Number of finished (full, single-color) tubes on the current board.
    var sortedCount: Int { gameState.tubes.reduce(0) { $0 + ($1.isComplete ? 1 : 0) } }

    /// Total number of tubes on the board.
    var tubeCount: Int { gameState.tubes.count }

    /// Whether there is at least one move to undo.
    var canUndo: Bool { !history.isEmpty }

    /// The difficulty band to display: the exact grade if computed, else the
    /// curve's instant estimate. Always has a value.
    var difficultyBand: Difficulty.Band {
        difficulty?.band ?? curve.estimatedBand(forLevel: level)
    }

    /// Seconds elapsed on the current level. The clock is read on access (not
    /// published per tick), so drive the display with a `TimelineView`.
    var elapsed: TimeInterval {
        guard let startedAt else { return frozenElapsed }
        return frozenElapsed + (now() - startedAt)
    }

    // MARK: - Interaction

    /// Handle a tap on tube `index`, implementing tap-lift / tap-drop.
    ///
    /// - No selection: lift a non-empty tube; ignore an empty one.
    /// - Tapping the lifted tube again: cancel the selection.
    /// - Otherwise attempt `from → index`: apply if legal (snapshot for undo,
    ///   count++, record the drop, clear selection, stop the clock on a win); if
    ///   illegal, switch selection to `index` when non-empty, else clear it.
    func tap(_ index: Int) {
        guard let source = selectedTube else {
            lastDrop = nil
            if !isEmptyTube(index) {
                selectedTube = index
            }
            return
        }

        if source == index {
            cancelSelection()
            return
        }

        let move = Move(from: source, to: index)
        if gameState.isLegal(move), let next = gameState.apply(move) {
            history.append(gameState)
            gameState = next
            moveCount += 1
            lastDrop = index
            selectedTube = nil
            if gameState.isWon { stopTimer() }
        } else {
            lastDrop = nil
            selectedTube = isEmptyTube(index) ? nil : index
        }
    }

    /// Drop the current selection without applying a move.
    func cancelSelection() {
        selectedTube = nil
        lastDrop = nil
    }

    /// Revert the most recent move, restoring the prior board. No-op when there is
    /// nothing to undo.
    func undo() {
        guard let previous = history.popLast() else { return }
        gameState = previous
        moveCount = max(0, moveCount - 1)
        selectedTube = nil
        lastDrop = nil
        // Undoing out of a solved board resumes the clock.
        if !gameState.isWon { startTimer() }
    }

    /// Reset the current level to its starting board, clearing history, counters,
    /// and the clock.
    func restart() {
        gameState = initialState
        history.removeAll()
        moveCount = 0
        selectedTube = nil
        lastDrop = nil
        resetTimer()
        startTimer()
    }

    /// Advance to the next level: generate the next board along the curve and reset
    /// all per-level state. No-op when progression is disabled (pinned board).
    func nextLevel() {
        guard let generator else { return }
        level += 1
        let state = Self.makeLevel(
            forLevel: level, generator: generator, curve: curve, seed: seed
        )
        gameState = state
        initialState = state
        history.removeAll()
        moveCount = 0
        selectedTube = nil
        lastDrop = nil
        resetTimer()
        startTimer()
        scheduleGrading()
    }

    // MARK: - Timer helpers

    private func startTimer() {
        if startedAt == nil { startedAt = now() }
    }

    private func stopTimer() {
        guard let startedAt else { return }
        frozenElapsed += now() - startedAt
        self.startedAt = nil
    }

    private func resetTimer() {
        frozenElapsed = 0
        startedAt = nil
    }

    // MARK: - Difficulty grading

    /// Kick off exact BFS grading off the main actor, but only within feasible
    /// bounds; otherwise leave `difficulty` nil and rely on the curve estimate.
    private func scheduleGrading() {
        gradingTask?.cancel()
        difficulty = nil

        let params = curve.parameters(forLevel: level)
        guard params.colors <= Self.maxGradableColors,
              params.scrambleDepth <= Self.maxGradableScramble else {
            gradingTask = nil
            return
        }

        let state = gameState
        let solver = solver
        let grader = grader
        let token = level
        gradingTask = Task { [weak self] in
            let graded = await Task.detached(priority: .utility) {
                grader.grade(state, using: solver)
            }.value
            guard let self, !Task.isCancelled, self.level == token else { return }
            self.difficulty = graded
        }
    }

    // MARK: - Level generation

    /// Generate a non-won board for `level` from `curve`. The reverse-scramble walk
    /// can land back on a solved board, so step a deterministic seed sequence (or
    /// retry the system RNG) and take the first state that isn't already won.
    private static func makeLevel(
        forLevel level: Int,
        generator: any LevelGenerating,
        curve: DifficultyCurve,
        seed: UInt64?
    ) -> GameState {
        let params = curve.parameters(forLevel: level)
        let attempts = 50

        if let seed {
            // Per-level base seed keeps the whole run reproducible.
            let base = seed &+ UInt64(level)
            for offset in 0..<UInt64(attempts) {
                var rng = SeededRandomNumberGenerator(seed: base &+ offset)
                let state = generate(params, generator: generator, rng: &rng)
                if !state.isWon { return state }
            }
            var rng = SeededRandomNumberGenerator(seed: base)
            return generate(params, generator: generator, rng: &rng)
        }

        for _ in 0..<attempts {
            var rng = SystemRandomNumberGenerator()
            let state = generate(params, generator: generator, rng: &rng)
            if !state.isWon { return state }
        }
        var rng = SystemRandomNumberGenerator()
        return generate(params, generator: generator, rng: &rng)
    }

    private static func generate<R: RandomNumberGenerator>(
        _ params: LevelParameters,
        generator: any LevelGenerating,
        rng: inout R
    ) -> GameState {
        generator.generate(
            colors: params.colors,
            capacity: params.capacity,
            emptyTubes: params.emptyTubes,
            scrambleDepth: params.scrambleDepth,
            using: &rng
        )
    }

    private func isEmptyTube(_ index: Int) -> Bool {
        guard gameState.tubes.indices.contains(index) else { return true }
        return gameState.tubes[index].isEmpty
    }
}
