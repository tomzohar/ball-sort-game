import SwiftUI
import BallSortCore

/// App entry point and composition root: constructs the concrete `Generator`,
/// `Solver`, and `DifficultyGrader`, and injects them into the root
/// `BoardViewModel`, which generates levels along the default rising
/// `DifficultyCurve` (ADR-0001). The game starts at level 1 and advances through
/// the curve as the player wins.
@main
struct BallSortApp: App {
    @State private var model = BoardViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
    }
}
