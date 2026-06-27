import SwiftUI
import BallSortCore

/// The game screen: the wooden tray + board over the dark backdrop, with the HUD,
/// difficulty badge, per-level controls, and the win overlay. This view stays dumb
/// — it maps `BoardViewModel` state onto value-driven child views and routes their
/// callbacks back to the model.
struct RootView: View {
    /// The game-loop state machine, injected by the composition root.
    let model: BoardViewModel
    /// The durable stats, injected by the composition root (E7.4).
    let statsStore: StatsStore

    /// Whether the stats sheet is presented.
    @State private var showingStats = false
    /// Whether the settings sheet is presented.
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 16) {
                topBar

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
        .sheet(isPresented: $showingStats) {
            StatsScreen(stats: statsStore.stats) { showingStats = false }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView { showingSettings = false }
        }
    }

    /// A slim top bar carrying the settings and stats buttons at the trailing edge.
    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.25), in: Circle())
            }
            .accessibilityLabel("Settings")

            Button {
                showingStats = true
            } label: {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.25), in: Circle())
            }
            .accessibilityLabel("Stats")
        }
        .padding(.horizontal, 16)
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
    return RootView(model: BoardViewModel(initialState: state), statsStore: StatsStore())
}
