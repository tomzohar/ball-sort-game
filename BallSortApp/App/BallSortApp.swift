import SwiftUI

/// App entry point. The composition root will construct the concrete generator,
/// solver, and persistence store here and inject them into the root ViewModel (ADR-0001).
@main
struct BallSortApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
