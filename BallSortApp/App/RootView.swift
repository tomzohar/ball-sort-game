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
    /// The per-level run history, injected by the composition root (E13).
    let historyStore: HistoryStore

    /// Whether the stats sheet is presented.
    @State private var showingStats = false
    /// Whether the settings sheet is presented.
    @State private var showingSettings = false

    /// First-run tutorial gate (E14.2). Absent/`false` ⇒ show the walkthrough over the
    /// board; set `true` when finished/skipped. Settings can reset it to replay.
    @AppStorage(Tutorial.hasSeenKey) private var hasSeenTutorial = false

    /// Regular width (iPad) gets roomier margins around the (now screen-filling) board.
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isRegular: Bool { horizontalSizeClass == .regular }

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 16) {
                topBar

                if model.isReplaying {
                    replayBanner
                }

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

                // The tray stretches to fill the space between the HUD and the controls,
                // so the board uses the screen instead of leaving a tall empty gap below.
                WoodenTray { BoardView(model: model) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, isRegular ? 48 : 12)

                BoardControlsView(
                    canHint: model.canHint,
                    canUndo: model.canUndo,
                    onHint: { withAnimation(.easeInOut) { model.requestHint() } },
                    onUndo: { withAnimation(.easeInOut) { model.undo() } },
                    onRestart: { withAnimation(.easeInOut) { model.restart() } }
                )
            }
            .padding(.top, 12)
            .padding(.bottom, isRegular ? 28 : 10)
            .padding(.horizontal, isRegular ? 24 : 0)

            if model.isGenerating {
                ZenColor.scrim.ignoresSafeArea()
                generatingOverlay
            } else if model.isWon {
                ZenColor.scrim.ignoresSafeArea()
                // A calm river-stone bloom behind the card so victory lands (E14.5).
                // Honours Reduce Motion internally (renders nothing when it's on).
                WinParticleBurst()
                // During a replay excursion there's no curve to advance, so the
                // primary action returns to the player's real current level (E13).
                WinOverlayView(
                    moves: model.moveCount,
                    elapsed: model.elapsed,
                    nextTitle: model.isReplaying ? "Done" : "Next Level",
                    onNextLevel: {
                        withAnimation(.easeInOut) {
                            if model.isReplaying { model.exitReplay() } else { model.nextLevel() }
                        }
                    },
                    onReplay: { withAnimation(.easeInOut) { model.restart() } }
                )
            }

            // First-run walkthrough, layered above everything so it greets the player
            // on launch and after a "How to play" replay from Settings (E14.2).
            if !hasSeenTutorial {
                ZenColor.scrim.ignoresSafeArea()
                    .transition(.opacity)
                TutorialOverlayView {
                    withAnimation(.easeInOut) { hasSeenTutorial = true }
                }
            }
        }
        .animation(.easeInOut, value: model.isWon)
        .animation(.easeInOut, value: model.isGenerating)
        .animation(.easeInOut, value: model.isReplaying)
        .animation(.easeInOut, value: hasSeenTutorial)
        .sheet(isPresented: $showingStats) {
            StatsScreen(
                stats: statsStore.stats,
                runs: historyStore.history.runs,
                onRetry: { run in
                    showingStats = false
                    withAnimation(.easeInOut) { model.replay(run) }
                },
                onClose: { showingStats = false }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView { showingSettings = false }
        }
    }

    /// A slim top bar carrying the settings and stats buttons at the trailing edge.
    /// Zen Garden secondary icon buttons (E12.9): calm `elevated` discs with a
    /// hairline `stoneFrame` border and a soft `rest` elevation, ≥44pt touch targets.
    private var topBar: some View {
        HStack(spacing: ZenSpacing.sm) {
            Spacer()
            Button {
                showingSettings = true
            } label: {
                ZenIconButtonLabel(systemImage: "gearshape.fill")
            }
            .accessibilityLabel("Settings")

            Button {
                showingStats = true
            } label: {
                ZenIconButtonLabel(systemImage: "chart.bar.fill")
            }
            .accessibilityLabel("Stats")
        }
        .padding(.horizontal, ZenSpacing.lg)
    }

    /// A calm banner shown while replaying a past level (E13): names the level being
    /// replayed and offers an Exit back to the player's real current level.
    private var replayBanner: some View {
        HStack(spacing: ZenSpacing.md) {
            Image(systemName: "arrow.counterclockwise")
                .foregroundStyle(ZenColor.accent)
            Text("Replaying Level \(model.level)")
                .font(ZenFont.headline)
                .foregroundStyle(ZenColor.textPrimary)
            Spacer(minLength: ZenSpacing.sm)
            Button { withAnimation(.easeInOut) { model.exitReplay() } } label: {
                Text("Exit")
                    .font(ZenFont.button)
                    .foregroundStyle(ZenColor.accent)
            }
            .accessibilityLabel("Exit replay")
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.vertical, ZenSpacing.sm)
        .padding(.horizontal, ZenSpacing.lg)
        .background(
            ZenColor.elevated,
            in: RoundedRectangle(cornerRadius: ZenRadius.md, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ZenRadius.md, style: .continuous)
                .strokeBorder(ZenColor.stoneFrame, lineWidth: 1)
        )
        .zenShadow(.rest)
        .padding(.horizontal, ZenSpacing.lg)
    }

    private var generatingOverlay: some View {
        ZenOverlayCard {
            VStack(spacing: ZenSpacing.lg) {
                RakeLineSweep()
                Text("Generating level…")
                    .font(ZenFont.status)
                    .foregroundStyle(ZenColor.textSecondary)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

/// A single rake line that sweeps the empty sand bed, looping calmly — the
/// Zen-Garden "loading" motif (E12.10). A thin accent line glides top→bottom over a
/// faint raked-bed backdrop, driven by `AnimationConstants.generatingSweep`.
private struct RakeLineSweep: View {
    @State private var sweeping = false

    private let bedHeight: CGFloat = 56
    private let bedWidth: CGFloat = 180

    var body: some View {
        ZStack {
            // Faint static "raked bed" lines so the swept line has something to comb.
            VStack(spacing: 7) {
                ForEach(0..<6, id: \.self) { _ in
                    Capsule()
                        .fill(ZenColor.stoneFrame.opacity(0.5))
                        .frame(height: 1.5)
                }
            }

            // The single rake line that sweeps across the bed.
            Capsule()
                .fill(ZenColor.accent)
                .frame(height: 2.5)
                .shadow(color: ZenColor.accent.opacity(0.5), radius: 4)
                .offset(y: sweeping ? bedHeight / 2 : -bedHeight / 2)
        }
        .frame(width: bedWidth, height: bedHeight)
        .clipShape(RoundedRectangle(cornerRadius: ZenRadius.sm, style: .continuous))
        .onAppear {
            withAnimation(AnimationConstants.generatingSweep) { sweeping = true }
        }
        .accessibilityHidden(true)
    }
}

/// A Zen Garden secondary icon button face: an SF Symbol centred on a calm
/// `elevated` disc with a hairline `stoneFrame` border and a soft `rest` shadow.
/// Sized to a ≥44pt touch target.
private struct ZenIconButtonLabel: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.title3)
            .foregroundStyle(ZenColor.textPrimary)
            .frame(width: 44, height: 44)
            .background(ZenColor.elevated, in: Circle())
            .overlay(Circle().strokeBorder(ZenColor.stoneFrame, lineWidth: 1))
            .zenShadow(.rest)
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
    return RootView(
        model: BoardViewModel(initialState: state),
        statsStore: StatsStore(),
        historyStore: HistoryStore()
    )
}
