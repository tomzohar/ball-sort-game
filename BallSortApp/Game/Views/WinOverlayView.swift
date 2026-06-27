import SwiftUI

/// The victory overlay shown when the level is solved: a celebratory card with the
/// final moves/time and the "next level" / "replay" actions.
///
/// A dumb view (ADR-0001) driven by plain values and callbacks; `RootView` owns the
/// dimmed backdrop and decides *when* to present it. The card borrows the prototype's
/// wooden-tray theme (warm gradient, dark border, glossy highlight) so the win moment
/// feels of-a-piece with the board (PROJECT_BRIEF, m3).
struct WinOverlayView: View {
    let moves: Int
    let elapsed: TimeInterval
    let onNextLevel: () -> Void
    let onReplay: () -> Void

    /// When `true`, the card renders in its settled (fully-visible) state instead of
    /// running the entrance animation. Snapshots/previews pass `true` for a stable,
    /// content-bearing baseline; production uses the default and animates in.
    var startsSettled: Bool = false

    private static var cornerRadius: CGFloat { 24 }

    /// Drives the staggered cascade entrance (emoji bounce → stats → buttons).
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
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)

        VStack(spacing: 18) {
            Text("🎉")
                .font(.system(size: 52))
                .accessibilityHidden(true)
                .scaleEffect(appeared ? 1 : 0.3)
                .opacity(appeared ? 1 : 0)
                .animation(AnimationConstants.winCelebration, value: appeared)

            Text("Solved!")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(AnimationConstants.winCelebration.delay(AnimationConstants.winStagger), value: appeared)

            stats
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)
                .animation(AnimationConstants.winCelebration.delay(AnimationConstants.winStagger * 2), value: appeared)

            VStack(spacing: 12) {
                Button(action: onNextLevel) {
                    Text("Next Level")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Color(hex: 0x36D44A))

                Button(action: onReplay) {
                    Text("Replay")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
            }
            .padding(.top, 4)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.9)
            .animation(AnimationConstants.winCelebration.delay(AnimationConstants.winStagger * 3), value: appeared)
        }
        .padding(28)
        .frame(maxWidth: 320)
        .background(cardBackground(shape: shape))
        .overlay(
            shape.strokeBorder(Color(hex: 0x5E3C1C), lineWidth: 5)
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.55), radius: 24, x: 0, y: 18)
        .transition(.scale.combined(with: .opacity))
        .onAppear { appeared = true }
    }

    /// "18 moves" + the formatted clock, shown as two labelled pills.
    private var stats: some View {
        HStack(spacing: 14) {
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
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.white)
            label
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(minWidth: 84)
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            Color.black.opacity(0.18),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    /// Warm wooden gradient with a glossy top highlight, mirroring `WoodenTray`.
    private func cardBackground(shape: RoundedRectangle) -> some View {
        LinearGradient(
            colors: [Color(hex: 0xC98A4B), Color(hex: 0x8A5A2B)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            LinearGradient(
                colors: [Color.white.opacity(0.28), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        )
        .clipShape(shape)
    }
}

#Preview {
    ZStack {
        GameBackground()
        Color.black.opacity(0.35).ignoresSafeArea()
        WinOverlayView(
            moves: 18,
            elapsed: 95,
            onNextLevel: {},
            onReplay: {}
        )
    }
}
