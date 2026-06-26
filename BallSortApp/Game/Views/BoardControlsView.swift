import SwiftUI

/// The per-level controls: undo the last move and restart the level. A dumb view
/// driven by plain values and callbacks.
///
/// Foundation stub (E5): minimal buttons; the polished styling lands in the E5
/// fan-out.
struct BoardControlsView: View {
    let canUndo: Bool
    let onUndo: () -> Void
    let onRestart: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button("Undo", action: onUndo)
                .disabled(!canUndo)
            Button("Restart", action: onRestart)
        }
        .font(.headline)
        .foregroundStyle(.white)
    }
}
