import SwiftUI
import BallSortCore

/// The stats sheet: the light Zen "stage" behind the `StatsView` card, with a Done
/// button to dismiss. Maps the durable `GameStats` model onto `StatsView`'s primitive
/// inputs (E7.4) — the view itself stays model-agnostic and dumb.
///
/// Restyled in the "Zen Garden" identity (E12.11): the dark game backdrop is replaced
/// by the light `ZenColor.stage`, and Done becomes a calm `accent` pill. Inputs (the
/// `GameStats` values), the localized strings, and the `onClose` dismissal are
/// unchanged.
struct StatsScreen: View {
    /// The stats to display.
    let stats: GameStats
    /// Invoked when the player taps Done.
    let onClose: () -> Void

    var body: some View {
        ZStack {
            ZenColor.stage.ignoresSafeArea()

            VStack(spacing: ZenSpacing.xl) {
                StatsView(
                    levelsSolved: stats.levelsSolved,
                    bestMoves: stats.bestMoves,
                    bestTimeSeconds: stats.bestTimeSeconds,
                    currentStreak: stats.currentStreak,
                    longestStreak: stats.longestStreak
                )

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
        }
    }
}

#Preview("Populated") {
    StatsScreen(
        stats: GameStats(
            levelsSolved: 42,
            bestMoves: 14,
            bestTimeSeconds: 73,
            currentStreak: 5,
            longestStreak: 12,
            lastSolvedDay: 20_260_627
        ),
        onClose: {}
    )
}

#Preview("Empty") {
    StatsScreen(stats: .empty, onClose: {})
}
