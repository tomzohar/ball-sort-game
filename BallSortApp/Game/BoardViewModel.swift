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
/// Level generation runs the solver to verify solvability, so it happens **off the
/// main actor** behind an `isGenerating` flag; the board appears once generation
/// completes. Dependencies (generator / solver / grader / curve / clock) are
/// injected with production defaults so the composition root can build it with
/// `BoardViewModel()`, and tests can pin a board (`init(initialState:)`) or fakes.
@MainActor
@Observable
final class BoardViewModel {
    /// The current board snapshot (an empty placeholder while a level generates).
    private(set) var gameState: GameState

    /// The lifted source tube awaiting a destination, or `nil` when nothing is
    /// selected.
    private(set) var selectedTube: Int?

    /// The number of net moves applied on the current level (undo decrements it).
    private(set) var moveCount: Int

    /// The destination tube of the most recent successful move — drives the
    /// drop animation — or `nil` when the last interaction wasn't a move.
    private(set) var lastDrop: Int?

    /// Bumped each time a move is rejected as illegal — drives the source-tube
    /// shake animation (E8.3). Monotonic; the value itself is meaningless, only
    /// the change matters.
    private(set) var illegalMoveNonce = 0

    /// The 1-based level the player is on.
    private(set) var level: Int

    /// `true` while a level is being generated (solver-verified) off the main actor.
    private(set) var isGenerating: Bool

    /// The exact difficulty grade once computed, else `nil`. Prefer `difficultyBand`
    /// for display — it always has a value.
    private(set) var difficulty: Difficulty?

    /// The solver's suggested next move, surfaced as a board highlight (E6), or
    /// `nil` when no hint is showing. Set by `requestHint()`; cleared by any board
    /// mutation (tap / undo / restart / level change).
    private(set) var hintMove: Move?

    /// `true` while a hint is being computed off the main actor.
    private(set) var isHinting: Bool = false

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

    /// The curve caps colors here; exact grading stays within solver-feasible sizes.
    private static let maxGradableColors = 5

    /// In-flight async work, exposed for deterministic test awaiting.
    @ObservationIgnored private(set) var generateTask: Task<Void, Never>?
    @ObservationIgnored private(set) var gradingTask: Task<Void, Never>?
    @ObservationIgnored private(set) var hintTask: Task<Void, Never>?

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
        self.isGenerating = false
        self.generator = generator
        self.solver = solver
        self.grader = grader
        self.curve = curve
        self.seed = seed
        self.now = now
    }

    /// Pins a fixed board with progression disabled — for tests and snapshots.
    /// Defaults make `BoardViewModel(initialState:)` the common case; tests inject a
    /// fake `solver` (hints) or a deterministic `now` (clock) as needed.
    convenience init(
        initialState: GameState,
        solver: some Solving = Solver(),
        now: @escaping () -> TimeInterval = { Date().timeIntervalSinceReferenceDate }
    ) {
        self.init(
            state: initialState,
            generator: nil,
            solver: solver,
            grader: DifficultyGrader(),
            curve: .default,
            level: 1,
            seed: nil,
            now: now
        )
        startTimer()
    }

    /// The production game loop: generates `startingLevel` from `curve` (off-main)
    /// and begins the difficulty progression. A non-`nil` `seed` makes the whole run
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
        let placeholder = Self.placeholder(for: curve.parameters(forLevel: lvl))
        self.init(
            state: placeholder,
            generator: generator,
            solver: solver,
            grader: grader,
            curve: curve,
            level: lvl,
            seed: seed,
            now: now
        )
        startGeneration(forLevel: lvl)
    }

    // MARK: - Derived state

    /// `true` once every tube is empty or a finished single-color stack.
    var isWon: Bool { !isGenerating && gameState.isWon }

    /// Whether `index` is the currently lifted source tube.
    func isSelected(_ index: Int) -> Bool { selectedTube == index }

    /// Number of finished (full, single-color) tubes on the current board.
    var sortedCount: Int { gameState.tubes.reduce(0) { $0 + ($1.isComplete ? 1 : 0) } }

    /// Total number of tubes on the board.
    var tubeCount: Int { gameState.tubes.count }

    /// Whether there is at least one move to undo.
    var canUndo: Bool { !history.isEmpty }

    /// Whether a hint can be requested right now (a live, unsolved board).
    var canHint: Bool { !isGenerating && !isWon }

    /// Whether tube `index` is the source of the active hint.
    func isHintSource(_ index: Int) -> Bool { hintMove?.from == index }

    /// Whether tube `index` is the destination of the active hint.
    func isHintTarget(_ index: Int) -> Bool { hintMove?.to == index }

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

    /// Handle a tap on tube `index`, implementing tap-lift / tap-drop. Ignored while
    /// a level is generating.
    func tap(_ index: Int) {
        guard !isGenerating else { return }
        clearHint()

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
            illegalMoveNonce += 1
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
        clearHint()
        gameState = previous
        moveCount = max(0, moveCount - 1)
        selectedTube = nil
        lastDrop = nil
        if !gameState.isWon { startTimer() }
    }

    /// Reset the current level to its starting board, clearing history, counters,
    /// and the clock. Ignored while a level is generating.
    func restart() {
        guard !isGenerating else { return }
        clearHint()
        gameState = initialState
        history.removeAll()
        moveCount = 0
        selectedTube = nil
        lastDrop = nil
        resetTimer()
        startTimer()
    }

    /// Advance to the next level: generate the next board along the curve (off-main).
    /// No-op when progression is disabled (pinned board).
    func nextLevel() {
        guard generator != nil else { return }
        level += 1
        startGeneration(forLevel: level)
    }

    // MARK: - Hints

    /// Compute the solver's next-best move off the main actor and surface it as
    /// `hintMove` for the board to highlight (E6). No-op on a generating or won
    /// board, or while a hint is already in flight. The solve is the same BFS used
    /// for grading, so it runs detached to keep taps responsive. This is the seam a
    /// future rewarded-ad gate would wrap.
    func requestHint() {
        guard canHint, !isHinting else { return }
        cancelSelection()

        let state = gameState
        let solver = solver
        let token = level
        isHinting = true
        hintTask = Task { [weak self] in
            let move = await Task.detached(priority: .userInitiated) {
                solver.solve(state)?.first
            }.value
            guard let self, !Task.isCancelled else { return }
            // Discard if the board moved on (or advanced levels) while solving.
            guard self.level == token, self.gameState == state else {
                self.isHinting = false
                return
            }
            self.isHinting = false
            self.hintMove = move
        }
    }

    /// Drop any active hint and cancel an in-flight solve.
    private func clearHint() {
        hintTask?.cancel()
        hintTask = nil
        hintMove = nil
        isHinting = false
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

    // MARK: - Generation

    /// Generate `level` off the main actor, then install it. While running, the board
    /// shows an empty placeholder and interaction is disabled.
    private func startGeneration(forLevel level: Int) {
        guard let generator else { return }
        clearHint()
        gradingTask?.cancel()
        generateTask?.cancel()

        let params = curve.parameters(forLevel: level)
        isGenerating = true
        gameState = Self.placeholder(for: params)
        selectedTube = nil
        lastDrop = nil
        history.removeAll()
        moveCount = 0
        resetTimer()

        let levelSeed = seed.map { $0 &+ UInt64(level) }
        let token = level
        generateTask = Task { [weak self] in
            let state = await Task.detached(priority: .userInitiated) {
                Self.makeLevel(params: params, generator: generator, seed: levelSeed)
            }.value
            guard let self, !Task.isCancelled, self.level == token else { return }
            self.install(state)
        }
    }

    /// Install a freshly generated board and start the level.
    private func install(_ state: GameState) {
        gameState = state
        initialState = state
        isGenerating = false
        startTimer()
        scheduleGrading()
    }

    nonisolated private static func makeLevel(
        params: LevelParameters,
        generator: any LevelGenerating,
        seed: UInt64?
    ) -> GameState {
        if let seed {
            var rng = SeededRandomNumberGenerator(seed: seed)
            return generate(params, generator: generator, rng: &rng)
        }
        var rng = SystemRandomNumberGenerator()
        return generate(params, generator: generator, rng: &rng)
    }

    nonisolated private static func generate<R: RandomNumberGenerator>(
        _ params: LevelParameters,
        generator: any LevelGenerating,
        rng: inout R
    ) -> GameState {
        generator.generate(
            colors: params.colors,
            capacity: params.capacity,
            emptyTubes: params.emptyTubes,
            minMoves: params.minMoves,
            using: &rng
        )
    }

    /// An all-empty board matching `params`' tube count — shown while generating.
    private static func placeholder(for params: LevelParameters) -> GameState {
        let tubes = (0..<(params.colors + params.emptyTubes)).map { _ in
            Tube(balls: [], capacity: params.capacity)
        }
        return GameState(tubes: tubes, capacity: params.capacity)
    }

    // MARK: - Difficulty grading

    /// Grade the current board off the main actor (colors are curve-capped to a
    /// solver-feasible size). Leaves `difficulty` nil — and the badge on the curve
    /// estimate — if grading is skipped or superseded.
    private func scheduleGrading() {
        gradingTask?.cancel()
        difficulty = nil

        guard curve.parameters(forLevel: level).colors <= Self.maxGradableColors else {
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

    private func isEmptyTube(_ index: Int) -> Bool {
        guard gameState.tubes.indices.contains(index) else { return true }
        return gameState.tubes[index].isEmpty
    }
}
