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

    /// The most recent successful move, carrying its endpoints, the lifted ball's
    /// color, and a monotonic `nonce` — drives the pour-arc flight (E14.3). The view
    /// fires a one-shot animation whenever `nonce` changes; an identical from/to pair
    /// on a later move still retriggers because the nonce differs. Stays `nil` until
    /// the first move and is left untouched by undo/restart so neither replays a flight.
    private(set) var lastMove: AnimatedMove?
    private var moveNonce = 0

    /// Bumped each time a move is rejected as illegal — drives the source-tube
    /// shake animation (E8.3). Monotonic; the value itself is meaningless, only
    /// the change matters.
    private(set) var illegalMoveNonce = 0

    /// The 1-based level the player is on.
    private(set) var level: Int

    /// `true` while a level is being generated (solver-verified) off the main actor.
    private(set) var isGenerating: Bool

    /// `true` while replaying a past level as a side excursion (E13). In this mode
    /// progression is suspended: the current level's saved snapshot is left untouched
    /// (`persistProgress()` is suppressed) and `exitReplay()` restores it. A replay
    /// win sharpens records but does not advance the curve.
    private(set) var isReplaying = false

    /// The level a replay started from, stashed in memory so `exitReplay()` can
    /// restore it. Non-`nil` exactly while `isReplaying`.
    private var replayStash: ReplayStash?

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
    private let feedback: any GameFeedbackPlaying

    /// The store the in-progress level is snapshotted to (E7.1), or `nil` to
    /// disable persistence (pinned test/snapshot boards).
    private let persistence: (any PersistenceStore)?

    /// Records wins into durable stats on win (E7.2), or `nil` to skip recording.
    private let statsStore: StatsStore?

    /// Records each win as a replayable run in the per-level history (E13), or `nil`
    /// to skip recording.
    private let historyStore: HistoryStore?

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
        now: @escaping () -> TimeInterval,
        feedback: any GameFeedbackPlaying,
        persistence: (any PersistenceStore)?,
        statsStore: StatsStore?,
        historyStore: HistoryStore?
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
        self.feedback = feedback
        self.persistence = persistence
        self.statsStore = statsStore
        self.historyStore = historyStore
    }

    /// Pins a fixed board with progression disabled — for tests and snapshots.
    /// Defaults make `BoardViewModel(initialState:)` the common case; tests inject a
    /// fake `solver` (hints) or a deterministic `now` (clock) as needed.
    convenience init(
        initialState: GameState,
        solver: some Solving = Solver(),
        now: @escaping () -> TimeInterval = { Date().timeIntervalSinceReferenceDate },
        feedback: (any GameFeedbackPlaying)? = nil,
        persistence: (any PersistenceStore)? = nil,
        statsStore: StatsStore? = nil,
        historyStore: HistoryStore? = nil
    ) {
        self.init(
            state: initialState,
            generator: nil,
            solver: solver,
            grader: DifficultyGrader(),
            curve: .default,
            level: 1,
            seed: nil,
            now: now,
            feedback: feedback ?? NoFeedback(),
            persistence: persistence,
            statsStore: statsStore,
            historyStore: historyStore
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
        now: @escaping () -> TimeInterval = { Date().timeIntervalSinceReferenceDate },
        feedback: (any GameFeedbackPlaying)? = nil,
        persistence: (any PersistenceStore)? = nil,
        statsStore: StatsStore? = nil,
        historyStore: HistoryStore? = nil
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
            now: now,
            feedback: feedback ?? GameFeedbackService(),
            persistence: persistence,
            statsStore: statsStore,
            historyStore: historyStore
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
                feedback.play(.lift)
            }
            return
        }

        if source == index {
            cancelSelection()
            return
        }

        let move = Move(from: source, to: index)
        if gameState.isLegal(move), let next = gameState.apply(move) {
            commitMove(move, next: next)
        } else {
            illegalMoveNonce += 1
            lastDrop = nil
            selectedTube = isEmptyTube(index) ? nil : index
            // The `source == index` re-selection case returned earlier, so reaching
            // here means a distinct destination was tapped and the move was rejected.
            feedback.play(.illegalMove)
        }
    }

    /// Drag-to-pour (E14.4): pour the top ball of `source` onto `destination` as a
    /// single self-contained gesture, independent of the tap selection toggle. It runs
    /// the move through the same legality + feedback + animation seam as tap-to-drop
    /// (`commitMove`), so a poured move is indistinguishable from a tapped one.
    ///
    /// A drag that ends on the same tube it started, on an empty source, or while a
    /// level is generating just clears the lift — those are cancels, not rejections, so
    /// they don't fire the illegal-move shake.
    func pour(from source: Int, to destination: Int) {
        guard !isGenerating else { return }
        clearHint()
        guard source != destination, !isEmptyTube(source) else {
            cancelSelection()
            return
        }

        let move = Move(from: source, to: destination)
        if gameState.isLegal(move), let next = gameState.apply(move) {
            commitMove(move, next: next)
        } else {
            // Keep the dragged-from tube selected so the existing shake — which reads
            // `selectedTube` — bounces the source the ball falls back into.
            selectedTube = source
            illegalMoveNonce += 1
            lastDrop = nil
            feedback.play(.illegalMove)
        }
    }

    /// Applies an already-validated legal `move` (with its precomputed `next` board) and
    /// fires every consequence of a drop: history push, counters, the pour-arc seam
    /// (`lastMove`), win / tube-complete bookkeeping, feedback, and persistence. Shared
    /// by tap-to-drop and drag-to-pour (E14.4) so both routes behave identically.
    private func commitMove(_ move: Move, next: GameState) {
        let source = move.from
        let destination = move.to
        let completedBefore = gameState.tubes.reduce(0) { $0 + ($1.isComplete ? 1 : 0) }
        // The lifted ball is the source's top, read before the board mutates.
        let movedColor = gameState.tubes[source].top
        history.append(gameState)
        gameState = next
        moveCount += 1
        lastDrop = destination
        if let movedColor {
            moveNonce += 1
            lastMove = AnimatedMove(from: source, to: destination, color: movedColor, nonce: moveNonce)
        }
        selectedTube = nil
        let completedAfter = gameState.tubes.reduce(0) { $0 + ($1.isComplete ? 1 : 0) }
        if gameState.isWon {
            stopTimer()
            if isReplaying {
                // A practice excursion: sharpen records only, don't advance the
                // curve or inflate the solved count / streak (E13).
                statsStore?.recordBests(moves: moveCount, seconds: elapsed)
            } else {
                statsStore?.recordWin(moves: moveCount, seconds: elapsed)
            }
            // `initialState` is this level's starting board — snapshot it so the
            // run can be replayed as the exact same puzzle (E13).
            historyStore?.record(
                level: level,
                board: initialState,
                moves: moveCount,
                seconds: elapsed
            )
            feedback.play(.win)
        } else if completedAfter > completedBefore {
            feedback.play(.tubeComplete)
        } else {
            feedback.play(.drop)
        }
        persistProgress()
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
        feedback.play(.undo)
        persistProgress()
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
        persistProgress()
    }

    /// Advance to the next level: generate the next board along the curve (off-main).
    /// No-op when progression is disabled (pinned board) or while replaying — a
    /// replay is a side excursion that never advances the curve.
    func nextLevel() {
        guard generator != nil, !isReplaying else { return }
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
            // Sound + soft haptic the moment the nudge surfaces, so the cue lands with
            // the on-board highlight (E14.7). A no-solution hint stays silent.
            if move != nil { self.feedback.play(.hint) }
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
}

// MARK: - Level generation & difficulty grading

extension BoardViewModel {

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
        persistProgress()
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

// MARK: - Persistence (E7)

extension BoardViewModel {

    /// Restores a persisted in-progress level (E7.1): installs the saved board
    /// directly — no generation — while keeping progression live so `nextLevel()`
    /// continues along the curve. The composition root uses this when a `SavedGame`
    /// was found on launch.
    convenience init(
        restoring saved: SavedGame,
        generator: some LevelGenerating = Generator(),
        solver: some Solving = Solver(),
        grader: DifficultyGrader = DifficultyGrader(),
        curve: DifficultyCurve = .default,
        seed: UInt64? = nil,
        now: @escaping () -> TimeInterval = { Date().timeIntervalSinceReferenceDate },
        feedback: (any GameFeedbackPlaying)? = nil,
        persistence: (any PersistenceStore)? = nil,
        statsStore: StatsStore? = nil,
        historyStore: HistoryStore? = nil
    ) {
        self.init(
            state: saved.gameState,
            generator: generator,
            solver: solver,
            grader: grader,
            curve: curve,
            level: saved.level,
            seed: seed,
            now: now,
            feedback: feedback ?? GameFeedbackService(),
            persistence: persistence,
            statsStore: statsStore,
            historyStore: historyStore
        )
        restore(from: saved)
    }

    /// Apply the non-board fields of `saved` (initial board, counters, clock) and
    /// resume the level. Split out so the designated init stays board-only.
    private func restore(from saved: SavedGame) {
        initialState = saved.initialState
        moveCount = saved.moveCount
        frozenElapsed = saved.elapsedSeconds
        startTimer()
        scheduleGrading()
    }

    /// Snapshot the in-progress level to the injected store (E7.1). A no-op when
    /// persistence is disabled (pinned boards) or while replaying (E13) — a replay is
    /// a side excursion that must not overwrite the player's real saved level.
    /// Failures are swallowed — a missed save just means the resume falls back to the
    /// last good snapshot.
    func persistProgress() {
        guard let persistence, !isReplaying else { return }
        let saved = SavedGame(
            level: level,
            gameState: gameState,
            initialState: initialState,
            moveCount: moveCount,
            elapsedSeconds: elapsed
        )
        try? persistence.save(saved, forKey: PersistenceKeys.savedGame)
    }
}

// MARK: - Replay excursion (E13)

extension BoardViewModel {

    /// Replay a past level as a side excursion: install `run`'s exact starting board
    /// and play it without disturbing the player's place on the difficulty curve.
    ///
    /// The current level is stashed in memory and the saved-game snapshot is left
    /// untouched (`persistProgress()` is suppressed while replaying), so a relaunch
    /// mid-replay resumes the real current level. `exitReplay()` restores it. No-op
    /// while a level is generating. Re-entrant: retrying a different run while already
    /// replaying keeps the original stash so exit still returns to the true current
    /// level.
    func replay(_ run: LevelRun) {
        guard !isGenerating else { return }
        clearHint()
        gradingTask?.cancel()
        generateTask?.cancel()

        if !isReplaying {
            replayStash = ReplayStash(
                level: level,
                gameState: gameState,
                initialState: initialState,
                moveCount: moveCount,
                history: history,
                elapsed: elapsed
            )
        }

        isReplaying = true
        isGenerating = false
        level = run.level
        gameState = run.board
        initialState = run.board
        history.removeAll()
        moveCount = 0
        selectedTube = nil
        lastDrop = nil
        resetTimer()
        startTimer()
        scheduleGrading()
    }

    /// Leave a replay and restore the stashed current level (board, history, counters,
    /// clock). No-op when not replaying.
    func exitReplay() {
        guard isReplaying, let stash = replayStash else { return }
        clearHint()
        gradingTask?.cancel()
        generateTask?.cancel()

        isReplaying = false
        replayStash = nil
        level = stash.level
        gameState = stash.gameState
        initialState = stash.initialState
        history = stash.history
        moveCount = stash.moveCount
        selectedTube = nil
        lastDrop = nil
        resetTimer()
        frozenElapsed = stash.elapsed
        if !gameState.isWon { startTimer() }
        scheduleGrading()
        persistProgress()
    }
}

// MARK: - Replay stash

/// A snapshot of the level a replay started from, held in memory so `exitReplay()`
/// can restore the player's real current level after a side excursion (E13).
private struct ReplayStash {
    let level: Int
    let gameState: GameState
    let initialState: GameState
    let moveCount: Int
    let history: [GameState]
    let elapsed: TimeInterval
}
