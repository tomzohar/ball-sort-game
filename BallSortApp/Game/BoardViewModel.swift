import Observation
import BallSortCore

/// Drives the game board's tap-lift / tap-drop interaction as an `@Observable`
/// state machine. Move legality and application are delegated entirely to
/// `BallSortCore` (classic ball-sort rule); this view model only tracks the
/// selection, move count, and the most recent drop for animation.
///
/// DI of generator/solver/persistence is deferred to E5 — this unit takes only
/// an initial `GameState` so the board can be played and restarted.
@Observable
final class BoardViewModel {
    /// The current board snapshot.
    private(set) var gameState: GameState

    /// The lifted source tube awaiting a destination, or `nil` when nothing is
    /// selected.
    private(set) var selectedTube: Int?

    /// The number of successful moves applied since the last restart.
    private(set) var moveCount: Int

    /// The destination tube of the most recent successful move — drives the
    /// drop animation — or `nil` when the last interaction wasn't a move.
    private(set) var lastDrop: Int?

    /// The state the board resets to on `restart()`.
    private let initialState: GameState

    init(initialState: GameState) {
        self.gameState = initialState
        self.initialState = initialState
        self.selectedTube = nil
        self.moveCount = 0
        self.lastDrop = nil
    }

    /// `true` once every tube is empty or a finished single-color stack.
    var isWon: Bool { gameState.isWon }

    /// Whether `index` is the currently lifted source tube.
    func isSelected(_ index: Int) -> Bool { selectedTube == index }

    /// Handle a tap on tube `index`, implementing tap-lift / tap-drop.
    ///
    /// - No selection: lift a non-empty tube; ignore an empty one.
    /// - Tapping the lifted tube again: cancel the selection.
    /// - Otherwise attempt `from → index`: apply if legal (count++, record the
    ///   drop, clear selection); if illegal, switch selection to `index` when
    ///   it is non-empty, else clear it.
    func tap(_ index: Int) {
        guard let source = selectedTube else {
            // No current selection: lift a non-empty tube, ignore an empty one.
            lastDrop = nil
            if !isEmptyTube(index) {
                selectedTube = index
            }
            return
        }

        if source == index {
            // Tapping the lifted tube cancels the selection.
            cancelSelection()
            return
        }

        let move = Move(from: source, to: index)
        if gameState.isLegal(move), let next = gameState.apply(move) {
            gameState = next
            moveCount += 1
            lastDrop = index
            selectedTube = nil
        } else {
            // Illegal move: re-target the selection to the tapped tube when it
            // holds balls, otherwise clear the selection entirely.
            lastDrop = nil
            selectedTube = isEmptyTube(index) ? nil : index
        }
    }

    /// Drop the current selection without applying a move.
    func cancelSelection() {
        selectedTube = nil
        lastDrop = nil
    }

    /// Reset the board to its initial state, clearing all interaction state.
    func restart() {
        gameState = initialState
        moveCount = 0
        selectedTube = nil
        lastDrop = nil
    }

    private func isEmptyTube(_ index: Int) -> Bool {
        guard gameState.tubes.indices.contains(index) else { return true }
        return gameState.tubes[index].isEmpty
    }
}
