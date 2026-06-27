import SwiftUI
import BallSortCore

/// The game screen: the wooden tray + board over the dark backdrop, with the HUD,
/// difficulty badge, per-level controls, and the win overlay. This view stays dumb
/// — it maps `BoardViewModel` state onto value-driven child views and routes their
/// callbacks back to the model.
struct RootView: View {
    /// The game-loop state machine, injected by the composition root.
    let model: BoardViewModel

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 16) {
                DifficultyBadgeView(level: model.level, band: model.difficultyBand)

                // The HUD's clock ticks live via a TimelineView re-reading `elapsed`.
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    GameHUDView(
                        moves: model.moveCount,
                        elapsed: model.elapsed,
                        sortedCount: model.sortedCount,
                        tubeCount: model.tubeCount
                    )
                }

                WoodenTray { BoardView(model: model) }
                    .padding(.horizontal, 12)

                BoardControlsView(
                    canHint: model.canHint,
                    canUndo: model.canUndo,
                    onHint: { withAnimation(.easeInOut) { model.requestHint() } },
                    onUndo: { withAnimation(.easeInOut) { model.undo() } },
                    onRestart: { withAnimation(.easeInOut) { model.restart() } }
                )

                Spacer(minLength: 0)
            }
            .padding(.top, 12)

            if model.isGenerating {
                Color.black.opacity(0.35).ignoresSafeArea()
                generatingOverlay
            } else if model.isWon {
                Color.black.opacity(0.35).ignoresSafeArea()
                WinOverlayView(
                    moves: model.moveCount,
                    elapsed: model.elapsed,
                    onNextLevel: { withAnimation(.easeInOut) { model.nextLevel() } },
                    onReplay: { withAnimation(.easeInOut) { model.restart() } }
                )
            }
        }
        .animation(.easeInOut, value: model.isWon)
        .animation(.easeInOut, value: model.isGenerating)
    }

    private var generatingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text("Generating level…")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    let state = GameState(
        tubes: [
            Tube(balls: [.blue, .pink, .green, .yellow], capacity: 4),
            Tube(balls: [.yellow, .green, .pink, .blue], capacity: 4),
            Tube(balls: [.green, .blue, .yellow, .pink], capacity: 4),
            Tube(balls: [.pink, .yellow, .blue, .green], capacity: 4),
            Tube(balls: [], capacity: 4),
            Tube(balls: [], capacity: 4)
        ],
        capacity: 4
    )
    return RootView(model: BoardViewModel(initialState: state))
}
