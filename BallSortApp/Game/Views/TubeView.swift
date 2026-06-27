import SwiftUI
import BallSortCore

/// A single tube: a gravity-stacked column of balls over empty "dimple" cells,
/// ported from the prototype's `.col` / `.cell` styling.
///
/// Dumb view (ADR-0001): it renders a `Tube` and reports taps; all move logic
/// lives in `BoardViewModel` / `BallSortCore`. Sizing comes from `BoardLayout`.
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
    /// Invoked when the tube is tapped.
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: BoardLayout.ballGap) {
            ForEach(0..<capacity, id: \.self) { slot in
                cell(at: slot)
            }
        }
        .padding(.vertical, BoardLayout.tubeVerticalPadding)
        .padding(.horizontal, BoardLayout.tubeHorizontalPadding)
        .frame(
            width: BoardLayout.tubeWidth(ballSize: ballSize),
            height: BoardLayout.tubeHeight(ballSize: ballSize, capacity: capacity)
        )
        .background(highlight)
        .scaleEffect(flourishing ? 1.08 : 1.0)
        // "Tube complete" glow pulse (E8.3); inert otherwise.
        .shadow(color: flourishing ? Color(hex: 0x36D44A).opacity(0.85) : .clear, radius: 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        // Treat the whole tube as one VoiceOver element with a descriptive label
        // (index, fill, top color, and a state suffix) — the stacked balls are
        // decorative detail VoiceOver shouldn't read one-by-one (E9.4).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Accessibility

    /// A spoken description of this tube: its 1-based index, fill level, top ball
    /// color (or "empty"), plus a selected / target / complete suffix (E9.4).
    private var accessibilityLabel: String {
        var parts = ["Tube \(tubeIndex + 1)"]
        if tube.isEmpty {
            parts.append("empty")
        } else {
            parts.append("\(tube.count) of \(capacity) balls")
            if let top = tube.top {
                parts.append("top \(top.accessibilityColorName)")
            }
            if tube.isComplete {
                parts.append("complete")
            }
        }
        if isSelected {
            parts.append("selected")
        } else if isTarget {
            parts.append("can drop here")
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
        if let color = slotsTopToBottom[slot] {
            let lifted = isSelected && slot == topBallSlot
            BallView(color: color, size: ballSize, isLifted: lifted)
                // Prototype lifts the selected top ball ~10px (`translateY(-10px)`).
                .offset(y: lifted ? -10 : 0)
                .animation(AnimationConstants.ballLift, value: lifted)
        } else {
            EmptyCell(size: ballSize)
        }
    }

    // MARK: - Tube state highlight

    @ViewBuilder
    private var highlight: some View {
        let shape = RoundedRectangle(cornerRadius: BoardLayout.tubeCornerRadius, style: .continuous)
        let gold = Color(hex: 0xFFC400)
        if isHintSource {
            // Hint source (E6): warm gold glow + solid border — "lift from here".
            shape
                .fill(gold.opacity(0.20))
                .overlay(shape.strokeBorder(gold.opacity(0.95), lineWidth: 2.5))
        } else if isHintTarget {
            // Hint destination (E6): same gold, dashed border — "drop here".
            shape
                .fill(gold.opacity(0.12))
                .overlay(
                    shape.strokeBorder(
                        gold.opacity(0.85),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                )
        } else if isTarget {
            // Prototype `.col.target`: green tint + inset white border.
            shape
                .fill(Color(hex: 0x36D44A).opacity(0.12))
                .overlay(shape.strokeBorder(Color.white.opacity(0.35), lineWidth: 2))
        } else if isSelected {
            // Prototype `.col.selected`: faint white wash.
            shape.fill(Color.white.opacity(0.12))
        }
    }
}

/// An empty tube slot: a sunken dark dimple, ported from the prototype's `.cell`.
private struct EmptyCell: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.30), Color.clear]),
                    center: UnitPoint(x: 0.5, y: 0.6),
                    startRadius: 0,
                    endRadius: size * 0.6
                )
            )
            // Approximate the prototype's `inset 0 4px 7px rgba(0,0,0,.45)`.
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.45), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .blur(radius: 3)
                    .mask(Circle().stroke(lineWidth: 6))
            )
            .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        GameBackground()
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
        }
        .padding(40)
    }
}
