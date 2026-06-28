import SwiftUI
import BallSortCore

/// A single tube: a Zen Garden "frosted-glass cylinder in sand" (E12.5) holding a
/// gravity-stacked column of balls over empty "dimple" slots sunk into the sand bed.
///
/// Dumb view (ADR-0001): it renders a `Tube` and reports taps; all move logic
/// lives in `BoardViewModel` / `BallSortCore`. Sizing comes from `BoardLayout`;
/// the look comes from the `Zen*` tokens (`ZenColor`, `ZenRadius`, `ZenShadow`).
///
/// Visual states, all derived from existing inputs:
/// - **empty** — the resting frosted cylinder with all dimple slots.
/// - **idle** — partially/fully filled, no selection involved.
/// - **selected** — lifted source tube: accent (water) rim + glow.
/// - **target** — a legal destination: accent rim + soft glow ("drop here").
/// - **complete** — single-color full tube: success (moss) rim + glow.
struct TubeView: View {
    /// The tube to render (balls ordered bottom `[0]` → top `.last`).
    let tube: Tube
    /// 0-based position of this tube on the board; surfaced 1-based in the
    /// VoiceOver label (E9.4). Defaults to 0 for previews / standalone use.
    var tubeIndex: Int = 0
    /// Shared tube capacity (number of slots, filled bottom-up).
    let capacity: Int
    /// Ball diameter for this layout, from `BoardLayout.ballSize`.
    let ballSize: CGFloat
    /// Vertical gap between stacked balls. Stretches the column to fill the tray
    /// height (`BoardLayout.filledBallGap`); defaults to the base gap for previews.
    var ballGap: CGFloat = BoardLayout.ballGap
    /// `true` when this is the lifted source tube (highlight + lift the top ball).
    let isSelected: Bool
    /// `true` when a selection exists and this tube is a legal destination.
    let isTarget: Bool
    /// `true` when this tube is the source of an active hint (E6).
    var isHintSource: Bool = false
    /// `true` when this tube is the destination of an active hint (E6).
    var isHintTarget: Bool = false
    /// `true` for the brief "tube complete" flourish (scale-bounce + glow pulse).
    var flourishing: Bool = false
    /// `true` while a pour is in flight toward this tube (E14.3): the just-landed top
    /// ball is held hidden so it appears to *arrive* with the flying ball rather than
    /// pop in instantly. The slot stays (an empty dimple) so the column doesn't reflow.
    var suppressTopBall: Bool = false
    /// Invoked when the tube is tapped.
    let onTap: () -> Void

    /// Skip the completion settle's motion (overshoot + ripple) under Reduce Motion;
    /// the tube's glow/scale flourish still reads the completion calmly (E14.6).
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Rising-edge counter for the completion settle (E14.6): bumped each time the tube
    /// flips into its complete flourish, so the final-ball overshoot + ripple fire once
    /// per completion rather than replaying when the `flourishing` flag clears.
    @State private var settleToken = 0

    /// The tube's settled visual state, derived purely from inputs.
    private var visualState: VisualState {
        if isHintSource { return .hintSource }
        if isHintTarget { return .hintTarget }
        if isSelected { return .selected }
        if isTarget { return .target }
        if tube.isComplete { return .complete }
        return .idle
    }

    /// Corner radius for the frosted cylinder. The mouth/foot read as a rounded
    /// capsule end; uses the `ZenRadius.lg` token (no `BoardLayout` math change).
    private var cornerRadius: CGFloat { ZenRadius.lg }

    var body: some View {
        VStack(spacing: ballGap) {
            ForEach(0..<capacity, id: \.self) { slot in
                cell(at: slot)
            }
        }
        .padding(.vertical, BoardLayout.tubeVerticalPadding)
        .padding(.horizontal, BoardLayout.tubeHorizontalPadding)
        .frame(
            width: BoardLayout.tubeWidth(ballSize: ballSize),
            height: BoardLayout.tubeHeight(ballSize: ballSize, capacity: capacity, ballGap: ballGap)
        )
        .background(frostedGlass)
        .overlay(rim)
        .scaleEffect(flourishing ? 1.06 : 1.0)
        // Resting elevation: a whisper of depth so the cylinder sits in the sand.
        .zenShadow(.rest)
        // State glow: accent (selection/target/hint) or success (complete/flourish).
        .shadow(color: glowColor, radius: flourishing ? 18 : 12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        // Treat the whole tube as one VoiceOver element with a descriptive label
        // (index, fill, top color, and a state suffix) — the stacked balls are
        // decorative detail VoiceOver shouldn't read one-by-one (E9.4).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        // Fire the final-ball settle once on the rising edge of the complete flourish.
        .onChange(of: flourishing) { _, nowFlourishing in
            if nowFlourishing { settleToken += 1 }
        }
    }

    // MARK: - Accessibility

    /// A spoken description of this tube: its 1-based index, fill level, top ball
    /// color (or "empty"), plus a selected / target / complete suffix (E9.4).
    ///
    /// Composed from localized fragments joined with ", " (E9.5). Each fragment goes
    /// through `String(localized:)` with a stable key so it stays translatable; the
    /// English output is identical to the pre-localization label.
    private var accessibilityLabel: String {
        var parts = [String(localized: "tube.index", defaultValue: "Tube \(tubeIndex + 1)")]
        if tube.isEmpty {
            parts.append(String(localized: "tube.empty", defaultValue: "empty"))
        } else {
            parts.append(
                String(localized: "tube.fill", defaultValue: "\(tube.count) of \(capacity) balls")
            )
            if let top = tube.top {
                parts.append(
                    String(localized: "tube.top", defaultValue: "top \(top.accessibilityColorName)")
                )
            }
            if tube.isComplete {
                parts.append(String(localized: "tube.complete", defaultValue: "complete"))
            }
        }
        if isSelected {
            parts.append(String(localized: "tube.selected", defaultValue: "selected"))
        } else if isTarget {
            parts.append(String(localized: "tube.canDrop", defaultValue: "can drop here"))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Slots

    /// Slot contents top → bottom: empty slots first, then balls with the top
    /// ball (`tube.balls.last`) rendered highest of the filled region.
    private var slotsTopToBottom: [BallColor?] {
        let emptyCount = max(0, capacity - tube.balls.count)
        let filled = Array(tube.balls.reversed()) // top ball first
        return Array(repeating: nil, count: emptyCount) + filled
    }

    /// Index of the top (liftable) ball within `slotsTopToBottom`, if any.
    private var topBallSlot: Int? {
        max(0, capacity - tube.balls.count) < capacity && !tube.balls.isEmpty
            ? max(0, capacity - tube.balls.count)
            : nil
    }

    @ViewBuilder
    private func cell(at slot: Int) -> some View {
        // `slot` is always in `0..<capacity` and `slotsTopToBottom` has exactly
        // `capacity` elements, so a direct index is safe.
        // Hold the top ball hidden while a pour is flying toward it (E14.3) so it
        // reveals on landing instead of popping in ahead of the flight.
        let hiddenForPour = suppressTopBall && slot == topBallSlot
        if let color = slotsTopToBottom[slot], !hiddenForPour {
            let lifted = isSelected && slot == topBallSlot
            BallView(color: color, size: ballSize, isLifted: lifted)
                // Lift the selected top ball ~10pt up over the tube mouth.
                .offset(y: lifted ? -10 : 0)
                .animation(AnimationConstants.ballLift, value: lifted)
                // The final ball "locks" into place when the tube completes (E14.6):
                // a small overshoot + a moss ripple, fired by `settleToken`. Attached to
                // the top ball always (inert at rest); skipped under Reduce Motion.
                .modifier(CompletionSettle(
                    enabled: slot == topBallSlot && !reduceMotion,
                    trigger: settleToken,
                    ballSize: ballSize
                ))
        } else {
            EmptyCell(size: ballSize)
        }
    }

    // MARK: - Frosted-glass cylinder

    /// The translucent frosted-glass body: a soft, lightly-tinted fill over the
    /// `sandBed` so the bed shows through like glass resting in the garden.
    @ViewBuilder
    private var frostedGlass: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            // Frost: a translucent veil of the sand bed, brightening toward the
            // top "mouth" so the cylinder reads as glass, not a flat panel.
            .fill(ZenColor.sandBed.opacity(0.55))
            .overlay(
                shape.fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            // A faint inner state wash so selected/target/complete tubes tint the glass.
            .overlay(shape.fill(stateWash))
    }

    /// The glass rim: a hairline `stoneFrame` border at rest, recoloured to the
    /// active state's accent so selection/target/complete read at a glance.
    private var rim: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(rimColor, lineWidth: rimWidth)
            .allowsHitTesting(false)
    }

    // MARK: - State styling

    /// A subtle interior tint applied over the frosted glass per state.
    private var stateWash: Color {
        switch visualState {
        case .idle:        return .clear
        case .selected:    return ZenColor.accent.opacity(0.14)
        case .target:      return ZenColor.accent.opacity(0.10)
        case .complete:    return ZenColor.success.opacity(0.14)
        case .hintSource:  return ZenColor.accent.opacity(0.18)
        case .hintTarget:  return ZenColor.accent.opacity(0.10)
        }
    }

    /// The rim color per state. Idle keeps the calm `stoneFrame` hairline; active
    /// states use accent (water) or success (moss).
    private var rimColor: Color {
        switch visualState {
        case .idle:        return ZenColor.stoneFrame.opacity(0.85)
        case .selected:    return ZenColor.accent
        case .target:      return ZenColor.accent.opacity(0.85)
        case .complete:    return ZenColor.success
        case .hintSource:  return ZenColor.accent
        case .hintTarget:  return ZenColor.accent.opacity(0.85)
        }
    }

    /// Rim weight: a hairline at rest, thicker when a state wants attention.
    private var rimWidth: CGFloat {
        switch visualState {
        case .idle:                          return 1.5
        case .target, .hintTarget:           return 2
        case .selected, .complete, .hintSource: return 2.5
        }
    }

    /// The soft outer glow color per state (drives the state `.shadow`). The
    /// complete flourish always glows moss regardless of selection.
    private var glowColor: Color {
        if flourishing { return ZenColor.success.opacity(0.85) }
        switch visualState {
        case .idle:        return .clear
        case .selected:    return ZenColor.accent.opacity(0.55)
        case .target:      return ZenColor.accent.opacity(0.40)
        case .complete:    return ZenColor.success.opacity(0.45)
        case .hintSource:  return ZenColor.accent.opacity(0.65)
        case .hintTarget:  return ZenColor.accent.opacity(0.45)
        }
    }

    /// The settled visual states a tube can be in (priority-ordered in `visualState`).
    private enum VisualState {
        case idle, selected, target, complete, hintSource, hintTarget
    }
}

/// An empty tube slot: a sunken sand "dimple" pressed into the bed, the Zen Garden
/// reskin of the prototype's dark `.cell` (E12.5). A soft radial shading darkens the
/// hollow with a faint top inset, so each empty slot reads as a scooped depression.
private struct EmptyCell: View {
    let size: CGFloat

    var body: some View {
        Circle()
            // The dimple floor: a touch darker than the sand bed, deepest at center.
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        ZenColor.sandBed.opacity(0.9),
                        ZenColor.stoneFrame.opacity(0.35)
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.55),
                    startRadius: 0,
                    endRadius: size * 0.6
                )
            )
            // Inset shadow rim — the lip of the scooped hollow, darkest at the top.
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.22), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blur(radius: 3)
                    .mask(Circle().stroke(lineWidth: 5))
            )
            // A whisper of catch-light along the lower lip of the dimple.
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.18)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
                    .blur(radius: 2)
                    .mask(Circle().stroke(lineWidth: 4))
            )
            .frame(width: size, height: size)
    }
}

/// The "lock into place" finish on a tube's final ball when it completes (E14.6): a
/// quick scale overshoot that settles back, plus a moss ripple radiating from the ball.
/// Both fire once per `trigger` change (the tube's `settleToken`). Attached to the top
/// ball unconditionally and inert at rest, so it observes the trigger without churning
/// view identity; `enabled` is `false` for non-top balls and under Reduce Motion, where
/// it passes the content through untouched.
private struct CompletionSettle: ViewModifier {
    let enabled: Bool
    let trigger: Int
    let ballSize: CGFloat

    func body(content: Content) -> some View {
        if enabled {
            content
                .keyframeAnimator(initialValue: 1.0, trigger: trigger) { view, scale in
                    view.scaleEffect(scale)
                } keyframes: { _ in
                    // Snap up, then settle back with a touch of bounce — a decisive "lock".
                    SpringKeyframe(1.16, duration: 0.14, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.30, spring: .bouncy)
                }
                .overlay { CompletionRipple(trigger: trigger, ballSize: ballSize) }
        } else {
            content
        }
    }
}

/// A single moss ring that blooms outward from the completed ball and fades, once per
/// `trigger` change. Inert (invisible) at rest; the keyframes run only when the trigger
/// flips, so it sits quietly on the top ball until the tube completes.
private struct CompletionRipple: View {
    let trigger: Int
    let ballSize: CGFloat

    /// Animatable ripple state: ring scale and stroke opacity.
    private struct RippleState {
        var scale: CGFloat
        var opacity: Double
    }

    var body: some View {
        Circle()
            .stroke(ZenColor.success, lineWidth: 2.5)
            .frame(width: ballSize, height: ballSize)
            .keyframeAnimator(
                initialValue: RippleState(scale: 0.7, opacity: 0),
                trigger: trigger
            ) { view, state in
                view.scaleEffect(state.scale).opacity(state.opacity)
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    CubicKeyframe(2.1, duration: 0.40)
                }
                KeyframeTrack(\.opacity) {
                    // Flash in, then fade as the ring grows.
                    CubicKeyframe(0.55, duration: 0.08)
                    CubicKeyframe(0.0, duration: 0.32)
                }
            }
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        GameBackground()
        WoodenTray {
            HStack(spacing: BoardLayout.tubeGap) {
                TubeView(
                    tube: Tube(balls: [.blue, .pink, .blue], capacity: 4),
                    capacity: 4, ballSize: 56, isSelected: false, isTarget: false, onTap: {}
                )
                TubeView(
                    tube: Tube(balls: [.green, .green], capacity: 4),
                    capacity: 4, ballSize: 56, isSelected: true, isTarget: false, onTap: {}
                )
                TubeView(
                    tube: Tube(balls: [.yellow], capacity: 4),
                    capacity: 4, ballSize: 56, isSelected: false, isTarget: true, onTap: {}
                )
                TubeView(
                    tube: Tube(balls: [.pink, .pink, .pink, .pink], capacity: 4),
                    capacity: 4, ballSize: 56, isSelected: false, isTarget: false, onTap: {}
                )
                TubeView(
                    tube: Tube(balls: [], capacity: 4),
                    capacity: 4, ballSize: 56, isSelected: false, isTarget: false, onTap: {}
                )
            }
        }
        .padding(40)
    }
}
