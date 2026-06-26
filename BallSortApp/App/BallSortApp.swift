import SwiftUI
import BallSortCore

/// App entry point and composition root: constructs the concrete `Generator`,
/// builds a starting level, and injects it into the root `BoardViewModel`
/// (ADR-0001). The full generator-driven difficulty curve and persistence are
/// wired in E5; E4 ships a single deterministic playable level.
@main
struct BallSortApp: App {
    @State private var model = BoardViewModel(initialState: BallSortApp.makeInitialLevel())

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }

    /// Build the starting board. Seeded for a deterministic first level until E5
    /// replaces this with the generator-driven progression.
    ///
    /// The reverse-scramble walk can land back on a solved board, so step through
    /// a deterministic seed sequence and take the first state that isn't already
    /// won (keeping the result reproducible).
    private static func makeInitialLevel() -> GameState {
        let generator = Generator()
        for seed in (UInt64(20_260_626)..<UInt64(20_260_726)) {
            let state = generator.generate(
                colors: 5, capacity: 4, emptyTubes: 2, scrambleDepth: 80, seed: seed
            )
            if !state.isWon { return state }
        }
        // Fallback (vanishingly unlikely): a deeper scramble at the first seed.
        return generator.generate(
            colors: 5, capacity: 4, emptyTubes: 2, scrambleDepth: 120, seed: 20_260_626
        )
    }
}
