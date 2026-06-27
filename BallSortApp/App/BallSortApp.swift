import SwiftUI
import BallSortCore

/// App entry point and composition root: constructs the concrete `Generator`,
/// `Solver`, `DifficultyGrader`, and the on-disk `JSONFileStore`, then injects
/// them into the root `BoardViewModel` and `StatsStore` (ADR-0001/0002). On
/// launch it restores a persisted in-progress level if one exists (E7.1),
/// otherwise it generates level 1 and advances through the rising
/// `DifficultyCurve` as the player wins.
@main
struct BallSortApp: App {
    @State private var model: BoardViewModel
    @State private var statsStore: StatsStore
    @State private var historyStore: HistoryStore

    /// The user's light/dark preference (Settings → Appearance). Read here so the
    /// choice is applied app-wide via `.preferredColorScheme`; `SettingsView` writes
    /// the same key. Defaults to `.system`.
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue

    init() {
        let persistence = JSONFileStore()
        let statsStore = StatsStore(persistence: persistence)
        let historyStore = HistoryStore(persistence: persistence)

        let savedGame: SavedGame?
        if let loaded = try? persistence.load(SavedGame.self, forKey: PersistenceKeys.savedGame) {
            savedGame = loaded
        } else {
            savedGame = nil
        }

        let model: BoardViewModel
        if let savedGame {
            model = BoardViewModel(
                restoring: savedGame,
                persistence: persistence,
                statsStore: statsStore,
                historyStore: historyStore
            )
        } else {
            model = BoardViewModel(
                persistence: persistence,
                statsStore: statsStore,
                historyStore: historyStore
            )
        }

        _model = State(initialValue: model)
        _statsStore = State(initialValue: statsStore)
        _historyStore = State(initialValue: historyStore)
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model, statsStore: statsStore)
                .preferredColorScheme(AppearanceMode(storedValue: appearanceRaw).colorScheme)
        }
    }
}
