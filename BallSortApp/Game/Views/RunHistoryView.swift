import SwiftUI
import BallSortCore

/// The per-level run history (E13): a scrollable list of solved levels, newest first,
/// each row showing the level number, moves, time, and date with a Retry action that
/// replays that exact puzzle.
///
/// A dumb view (ADR-0001) driven by a plain `[LevelRun]` and an `onRetry` callback;
/// `StatsScreen` owns presentation and `RootView` routes Retry into the board's
/// replay excursion. Styled in the Zen Garden identity with custom-drawn rows (not a
/// system `List`) so the surface stays of-a-piece and snapshot-stable.
struct RunHistoryView: View {
    /// Completed runs, newest first.
    let runs: [LevelRun]
    /// Invoked with the chosen run when the player taps Retry.
    let onRetry: (LevelRun) -> Void

    var body: some View {
        VStack(spacing: ZenSpacing.lg) {
            Text("History")
                .font(ZenFont.title)
                .foregroundStyle(ZenColor.textPrimary)

            if runs.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: ZenSpacing.sm) {
                        ForEach(runs) { run in
                            row(for: run)
                        }
                    }
                    .padding(.horizontal, ZenSpacing.xs)
                }
            }
        }
        .frame(maxWidth: 360)
    }

    private var emptyState: some View {
        VStack(spacing: ZenSpacing.sm) {
            Image(systemName: "leaf")
                .font(.largeTitle)
                .foregroundStyle(ZenColor.textSecondary)
            Text("No levels solved yet")
                .font(ZenFont.body)
                .foregroundStyle(ZenColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ZenSpacing.xxl)
    }

    /// One run rendered as a Zen pill: level + metadata on the left, Retry on the right.
    private func row(for run: LevelRun) -> some View {
        HStack(spacing: ZenSpacing.md) {
            VStack(alignment: .leading, spacing: ZenSpacing.xs / 2) {
                Text("Level \(run.level)")
                    .font(ZenFont.headline)
                    .foregroundStyle(ZenColor.textPrimary)
                Text(metadata(for: run))
                    .font(ZenFont.caption)
                    .foregroundStyle(ZenColor.textSecondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Spacer(minLength: ZenSpacing.sm)

            Button { onRetry(run) } label: {
                Text("Retry")
                    .font(ZenFont.button)
                    .foregroundStyle(ZenColor.elevated)
                    .padding(.vertical, ZenSpacing.sm)
                    .padding(.horizontal, ZenSpacing.lg)
                    .background(ZenColor.accent, in: Capsule(style: .continuous))
            }
            .accessibilityLabel("Retry level \(run.level)")
        }
        .padding(.vertical, ZenSpacing.md)
        .padding(.horizontal, ZenSpacing.lg)
        .background(
            ZenColor.sandBed,
            in: RoundedRectangle(cornerRadius: ZenRadius.md, style: .continuous)
        )
    }

    /// "12 moves · 1:23 · Jun 27, 2026" — the run's result line.
    private func metadata(for run: LevelRun) -> String {
        let movesWord = run.moves == 1 ? "move" : "moves"
        return "\(run.moves) \(movesWord) · \(formatClock(run.timeSeconds)) · \(formatDayKey(run.dayKey))"
    }
}

#Preview("Populated") {
    let board = GameState(
        tubes: [Tube(balls: [.blue, .blue], capacity: 2), Tube(balls: [], capacity: 2)],
        capacity: 2
    )
    func run(_ id: Int, level: Int, moves: Int, time: Double) -> LevelRun {
        LevelRun(
            id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, UInt8(id))),
            level: level, moves: moves, timeSeconds: time, dayKey: 20_260_627, board: board
        )
    }
    return ZStack {
        ZenColor.stage.ignoresSafeArea()
        RunHistoryView(
            runs: [run(1, level: 12, moves: 24, time: 95), run(2, level: 7, moves: 18, time: 61)],
            onRetry: { _ in }
        )
    }
}

#Preview("Empty") {
    ZStack {
        ZenColor.stage.ignoresSafeArea()
        RunHistoryView(runs: [], onRetry: { _ in })
    }
}
