import SwiftUI
import BallSortCore

/// The stats sheet: the light Zen "stage" behind a Summary / History pair, with a
/// Done button to dismiss. The Summary tab maps the durable `GameStats` onto
/// `StatsView` (E7.4); the History tab lists past runs and routes Retry into a replay
/// excursion (E13). The screen stays dumb — it forwards model values and callbacks.
///
/// Styled in the "Zen Garden" identity (E12.11): the light `ZenColor.stage` stage and
/// a calm `accent` Done pill.
struct StatsScreen: View {
    /// The aggregate stats to display.
    let stats: GameStats
    /// The per-level run history, newest first.
    let runs: [LevelRun]
    /// Invoked with the chosen run when the player taps Retry in the History tab.
    let onRetry: (LevelRun) -> Void
    /// Invoked when the player taps Done.
    let onClose: () -> Void

    /// Which tab is showing. Summary is the default landing tab.
    @State private var tab: Tab = .summary

    /// The two tabs of the stats sheet.
    enum Tab: Hashable {
        case summary
        case history
    }

    var body: some View {
        ZStack {
            ZenColor.stage.ignoresSafeArea()

            VStack(spacing: ZenSpacing.xl) {
                Picker("View", selection: $tab) {
                    Text("Summary").tag(Tab.summary)
                    Text("History").tag(Tab.history)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)

                switch tab {
                case .summary:
                    StatsView(
                        levelsSolved: stats.levelsSolved,
                        bestMoves: stats.bestMoves,
                        bestTimeSeconds: stats.bestTimeSeconds,
                        currentStreak: stats.currentStreak,
                        longestStreak: stats.longestStreak
                    )
                case .history:
                    RunHistoryView(runs: runs, onRetry: onRetry)
                }

                Button(action: onClose) {
                    Text("Done")
                        .font(ZenFont.body)
                        .foregroundStyle(ZenColor.elevated)
                        .padding(.vertical, ZenSpacing.md)
                        .padding(.horizontal, ZenSpacing.xxl)
                        .background(ZenColor.accent, in: Capsule(style: .continuous))
                        .zenShadow(.rest)
                }
            }
            .padding(.vertical, ZenSpacing.xl)
        }
    }
}

#Preview("Populated") {
    let board = GameState(
        tubes: [Tube(balls: [.blue, .blue], capacity: 2), Tube(balls: [], capacity: 2)],
        capacity: 2
    )
    return StatsScreen(
        stats: GameStats(
            levelsSolved: 42,
            bestMoves: 14,
            bestTimeSeconds: 73,
            currentStreak: 5,
            longestStreak: 12,
            lastSolvedDay: 20_260_627
        ),
        runs: [
            LevelRun(
                id: UUID(), level: 12, moves: 24, timeSeconds: 95, dayKey: 20_260_627, board: board
            )
        ],
        onRetry: { _ in },
        onClose: {}
    )
}

#Preview("Empty") {
    StatsScreen(stats: .empty, runs: [], onRetry: { _ in }, onClose: {})
}
