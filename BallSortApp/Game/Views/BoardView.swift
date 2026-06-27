import SwiftUI
import BallSortCore

/// The interactive game board: all tubes in a single row, driven by a
/// `BoardViewModel`. Balls shrink to fit the available width (prototype's flex
/// row) and the board takes an intrinsic height, so the wooden tray hugs it.
///
/// Dumb view (ADR-0001): it renders `model.gameState` and forwards taps. Ball
/// sizing comes from `BoardLayout`; the lift/drop motion is a spring applied
/// around each tap (prototype's bounce easing).
struct BoardView: View {
    /// The board state machine (observed; `@Observable`).
    let model: BoardViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var availableWidth: CGFloat = 0

    /// Horizontal shake offset applied to the rejected source tube. Driven by
    /// `model.illegalMoveNonce`; eased back to 0 by `AnimationConstants.shake`.
    @State private var shakeOffset: CGFloat = 0
    /// The tube index currently shaking (the source of the rejected move).
    @State private var shakeTube: Int?

    /// The tube playing the "complete" flourish, and a token so the same tube can
    /// replay the flourish on a later completion.
    @State private var flourishTube: Int?
    @State private var flourishToken = 0

    /// Bouncy spring approximating the prototype drop easing
    /// `cubic-bezier(.34, 1.4, .5, 1)` over ~0.28s. Defined in `AnimationConstants`.
    private var dropAnimation: Animation { AnimationConstants.drop }

    var body: some View {
        let tubes = model.gameState.tubes
        let capacity = model.gameState.capacity
        let maxBall = horizontalSizeClass == .regular ? 80.0 : BoardLayout.defaultMaxBall
        let ballSize = BoardLayout.ballSize(
            availableWidth: availableWidth,
            tubeCount: max(1, tubes.count),
            maxBall: maxBall
        )

        HStack(alignment: .bottom, spacing: BoardLayout.tubeGap) {
            ForEach(tubes.indices, id: \.self) { i in
                TubeView(
                    tube: tubes[i],
                    tubeIndex: i,
                    capacity: capacity,
                    ballSize: ballSize,
                    isSelected: model.isSelected(i),
                    isTarget: isTarget(i),
                    isHintSource: model.isHintSource(i),
                    isHintTarget: model.isHintTarget(i),
                    flourishing: flourishTube == i,
                    onTap: { withAnimation(dropAnimation) { model.tap(i) } }
                )
                .offset(x: shakeTube == i ? shakeOffset : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: BoardWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(BoardWidthKey.self) { availableWidth = $0 }
        .onChange(of: model.illegalMoveNonce) { _, _ in playShake() }
        .onChange(of: model.lastDrop) { _, _ in playFlourishIfTubeCompleted() }
    }

    /// Brief horizontal wobble on the rejected source tube. Derived purely from VM
    /// state (`selectedTube`) so the view stays dumb (ADR-0001).
    private func playShake() {
        shakeTube = model.selectedTube
        guard shakeTube != nil else { return }
        let amplitude: CGFloat = 9
        withAnimation(AnimationConstants.shake) { shakeOffset = -amplitude }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(AnimationConstants.shake) { shakeOffset = amplitude }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                withAnimation(AnimationConstants.shake) { shakeOffset = 0 }
            }
        }
    }

    /// When the most recent drop completed its destination tube, play a one-shot
    /// scale-bounce + glow on that tube. Derived in-view from existing VM state.
    private func playFlourishIfTubeCompleted() {
        guard let d = model.lastDrop,
              model.gameState.tubes.indices.contains(d),
              model.gameState.tubes[d].isComplete else { return }
        flourishToken += 1
        let token = flourishToken
        withAnimation(AnimationConstants.tubeCompleteFlourish) { flourishTube = d }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard token == flourishToken else { return }
            withAnimation(AnimationConstants.tubeCompleteFlourish) { flourishTube = nil }
        }
    }

    /// Whether tube `i` is a legal destination for the current selection.
    private func isTarget(_ i: Int) -> Bool {
        guard let from = model.selectedTube, from != i else { return false }
        return model.gameState.isLegal(Move(from: from, to: i))
    }
}

/// Preference carrying the board's available width up to its own layout pass.
private struct BoardWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
    return ZStack {
        GameBackground()
        WoodenTray { BoardView(model: BoardViewModel(initialState: state)) }
            .padding()
    }
}
