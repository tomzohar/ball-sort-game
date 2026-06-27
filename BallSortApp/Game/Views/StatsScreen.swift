import SwiftUI
import BallSortCore

/// The stats sheet: the dark game backdrop behind the `StatsView` card, with a
/// Done button to dismiss. Maps the durable `GameStats` model onto `StatsView`'s
/// primitive inputs (E7.4) — the view itself stays model-agnostic and dumb.
struct StatsScreen: View {
    /// The stats to display.
    let stats: GameStats
    /// Invoked when the player taps Done.
    let onClose: () -> Void

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 24) {
                StatsView(
                    levelsSolved: stats.levelsSolved,
                    bestMoves: stats.bestMoves,
                    bestTimeSeconds: stats.bestTimeSeconds,
                    currentStreak: stats.currentStreak,
                    longestStreak: stats.longestStreak
                )

                Button(action: onClose) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 36)
                        .background(
                            Color.black.opacity(0.25),
                            in: Capsule()
                        )
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
