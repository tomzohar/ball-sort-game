import SwiftUI

/// The victory overlay shown when the level is solved: a calm Zen-Garden card with the
/// final moves/time and the "next level" / "replay" actions.
///
/// A dumb view (ADR-0001) driven by plain values and callbacks; `RootView` owns the
/// dimmed scrim and decides *when* to present it. The card uses the shared
/// `ZenOverlayCard` surface so the win moment feels of-a-piece with the loading
/// overlay (E12.10, docs/design/ZEN_GARDEN.md). The headline is set in the brand
/// `ZenFont.display` for a distinct premium moment.
struct WinOverlayView: View {
    let moves: Int
    let elapsed: TimeInterval
    let onNextLevel: () -> Void
    let onReplay: () -> Void

    /// When `true`, the card renders in its settled (fully-visible) state instead of
    /// running the entrance animation. Snapshots/previews pass `true` for a stable,
    /// content-bearing baseline; production uses the default and animates in.
    var startsSettled: Bool = false

    /// Drives the staggered cascade entrance (headline → stats → buttons).
    /// Flips to `true` on appear so each element eases in on its own delay.
    @State private var appeared: Bool

    init(
        moves: Int,
        elapsed: TimeInterval,
        startsSettled: Bool = false,
        onNextLevel: @escaping () -> Void,
        onReplay: @escaping () -> Void
    ) {
        self.moves = moves
        self.elapsed = elapsed
        self.startsSettled = startsSettled
        self.onNextLevel = onNextLevel
        self.onReplay = onReplay
        _appeared = State(initialValue: startsSettled)
    }

    var body: some View {
        ZenOverlayCard {
            VStack(spacing: ZenSpacing.lg) {
                Text("Solved!")
                    .font(ZenFont.display)
                    .foregroundStyle(ZenColor.textPrimary)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .animation(AnimationConstants.winCelebration, value: appeared)

                stats
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .animation(AnimationConstants.winCelebration.delay(AnimationConstants.winStagger), value: appeared)

                buttons
                    .padding(.top, ZenSpacing.xs)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .animation(
                        AnimationConstants.winCelebration.delay(AnimationConstants.winStagger * 2),
                        value: appeared
                    )
            }
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear { appeared = true }
    }

    /// Primary "Next Level" action over a secondary "Replay".
    private var buttons: some View {
        VStack(spacing: ZenSpacing.md) {
            Button(action: onNextLevel) {
                Text("Next Level")
                    .font(ZenFont.button)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(ZenColor.accent)

            Button(action: onReplay) {
                Text("Replay")
                    .font(ZenFont.button)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(ZenColor.accent)
        }
    }

    /// "18 moves" + the formatted clock, shown as two labelled pills.
    private var stats: some View {
        HStack(spacing: ZenSpacing.md) {
            // The "move"/"moves" label is pluralized via the String Catalog (E9.5).
            // Because the label shows only the word (the count lives in the adjacent
            // value pill), a varies-by-plural rule isn't usable — xcstringstool requires
            // a plural to reference its number. So two top-level keys are selected by
            // count, the sanctioned pattern for a number-less plural.
            statPill(value: "\(moves)", label: Text(movesLabelKey))
            statPill(value: formatClock(elapsed), label: Text("time"))
        }
    }

    /// The singular/plural moves word, as a `LocalizedStringKey` so `Text` localizes it.
    private var movesLabelKey: LocalizedStringKey {
        moves == 1 ? "win.move" : "win.moves"
    }

    private func statPill(value: String, label: Text) -> some View {
        VStack(spacing: ZenSpacing.xs / 2) {
            Text(value)
                .font(ZenFont.statValue)
                .foregroundStyle(ZenColor.textPrimary)
            label
                .font(ZenFont.caption)
                .textCase(.uppercase)
                .foregroundStyle(ZenColor.textSecondary)
        }
        .frame(minWidth: 84)
        .padding(.vertical, ZenSpacing.sm + 2)
        .padding(.horizontal, ZenSpacing.md + 2)
        .background(
            ZenColor.stoneFrame.opacity(0.35),
            in: RoundedRectangle(cornerRadius: ZenRadius.sm, style: .continuous)
        )
    }
}

#Preview {
    ZStack {
        GameBackground()
        ZenColor.scrim.ignoresSafeArea()
        WinOverlayView(
            moves: 18,
            elapsed: 95,
            onNextLevel: {},
            onReplay: {}
        )
    }
}
