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

    /// Horizontal shake offset applied to the rejected source tube. Driven by
    /// `model.illegalMoveNonce`; eased back to 0 by `AnimationConstants.shake`.
    @State private var shakeOffset: CGFloat = 0
    /// The tube index currently shaking (the source of the rejected move).
    @State private var shakeTube: Int?

    /// The tube playing the "complete" flourish, and a token so the same tube can
    /// replay the flourish on a later completion.
    @State private var flourishTube: Int?
    @State private var flourishToken = 0

    /// Resolved outer frames of each tube in the board coordinate space, captured via a
    /// preference so the pour flight knows where to launch from and land (E14.3). Tube
    /// frames are fixed-size regardless of fill, so these are stable across a move.
    @State private var tubeRects: [Int: CGRect] = [:]
    /// The ball currently arcing between tubes, or `nil` when none is in flight.
    @State private var flight: PourFlight?
    /// Drives the in-flight ball along its parabola (0 = launch, 1 = land).
    @State private var flightProgress: CGFloat = 0
    /// The destination tube whose just-landed top ball is held hidden during the flight.
    @State private var suppressedTube: Int?

    /// The tube a drag-to-pour gesture lifted from, or `nil` when no drag is active
    /// (E14.4). Set on the first drag movement; cleared when the drag ends.
    @State private var dragSource: Int?

    /// Name of the coordinate space tube frames and the flying ball share.
    private static let boardSpace = "board"

    /// Bouncy spring approximating the prototype drop easing
    /// `cubic-bezier(.34, 1.4, .5, 1)` over ~0.28s. Defined in `AnimationConstants`.
    private var dropAnimation: Animation { AnimationConstants.drop }

    var body: some View {
        let tubes = model.gameState.tubes
        let capacity = model.gameState.capacity
        // Generous caps; the board fills the available area, so width/height is the
        // binding constraint rather than an artificially small ball size. iPad goes larger.
        let maxBall = horizontalSizeClass == .regular ? 170.0 : 120.0

        // Fill the whole tray: all tubes in one row, sized to the largest ball that fits
        // both the available width and height, centred within the area.
        GeometryReader { proxy in
            let ballSize = BoardLayout.fittedBallSize(
                available: proxy.size,
                tubeCount: tubes.count,
                capacity: capacity,
                maxBall: maxBall
            )
            // Stretch each column down the tray height with extra air between balls.
            let ballGap = BoardLayout.filledBallGap(
                availableHeight: proxy.size.height,
                capacity: capacity,
                ballSize: ballSize
            )

            ZStack(alignment: .topLeading) {
                HStack(alignment: .bottom, spacing: BoardLayout.tubeGap) {
                    ForEach(tubes.indices, id: \.self) { i in
                        TubeView(
                            tube: tubes[i],
                            tubeIndex: i,
                            capacity: capacity,
                            ballSize: ballSize,
                            ballGap: ballGap,
                            isSelected: model.isSelected(i),
                            isTarget: isTarget(i),
                            isHintSource: model.isHintSource(i),
                            isHintTarget: model.isHintTarget(i),
                            flourishing: flourishTube == i,
                            suppressTopBall: suppressedTube == i,
                            onTap: { withAnimation(dropAnimation) { model.tap(i) } }
                        )
                        .background(tubeFrameReporter(index: i))
                        .offset(x: shakeTube == i ? shakeOffset : 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // The poured ball, arcing over the rim from source mouth to landing slot.
                if let flight {
                    BallView(color: flight.color, size: ballSize)
                        .position(flight.launch)
                        .modifier(PourArcEffect(
                            progress: flightProgress,
                            launch: flight.launch,
                            land: flight.land,
                            peak: flight.peak
                        ))
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: Self.boardSpace)
            .gesture(pourDrag)
            .onPreferenceChange(TubeFramesKey.self) { tubeRects = $0 }
            .onChange(of: model.lastMove?.nonce) { _, _ in
                startPourFlight(ballSize: ballSize, ballGap: ballGap, capacity: capacity)
            }
        }
        .onChange(of: model.illegalMoveNonce) { _, _ in playShake() }
        .onChange(of: model.lastDrop) { _, _ in playFlourishIfTubeCompleted() }
    }

    // MARK: - Drag-to-pour (E14.4)

    /// Drag a source tube onto a destination as an alternative to tap-lift / tap-drop.
    /// The first movement lifts the tube under the finger (reusing `tap`, so it gets the
    /// same selection highlight + lift haptic and all legal targets glow); releasing over
    /// another tube pours via `model.pour`, which shares tap's legality, feedback, and
    /// pour-arc animation. Releasing on the source, in a gap, or on an empty source just
    /// drops the lift. A non-zero `minimumDistance` lets plain taps fall through to the
    /// per-tube tap gesture untouched.
    private var pourDrag: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .named(Self.boardSpace))
            .onChanged { value in
                guard dragSource == nil else { return }
                // Begin a drag only from a non-empty tube directly under the finger.
                guard let start = tubeContaining(value.startLocation),
                      model.gameState.tubes.indices.contains(start),
                      !model.gameState.tubes[start].isEmpty else { return }
                dragSource = start
                if model.selectedTube != start {
                    withAnimation(AnimationConstants.ballLift) { model.tap(start) }
                }
            }
            .onEnded { value in
                defer { dragSource = nil }
                guard let source = dragSource else { return }
                // Forgiving drop target: the tube the finger is over, else the nearest column.
                let dest = tubeContaining(value.location) ?? nearestTube(toX: value.location.x)
                if let dest, dest != source {
                    withAnimation(dropAnimation) { model.pour(from: source, to: dest) }
                } else {
                    model.cancelSelection()
                }
            }
    }

    /// The tube whose captured frame contains `point` (board coordinate space), if any.
    private func tubeContaining(_ point: CGPoint) -> Int? {
        tubeRects.first(where: { $0.value.contains(point) })?.key
    }

    /// The tube whose column is horizontally nearest `x` — a forgiving fallback so a
    /// release just above/below a tube still lands on it (single-row board).
    private func nearestTube(toX x: CGFloat) -> Int? {
        tubeRects.min(by: { abs($0.value.midX - x) < abs($1.value.midX - x) })?.key
    }

    /// Captures a tube's outer frame in the board coordinate space for the pour flight.
    private func tubeFrameReporter(index: Int) -> some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: TubeFramesKey.self,
                value: [index: geo.frame(in: .named(Self.boardSpace))]
            )
        }
    }

    /// Launches the pour-arc flight for the most recent move: a ball travels from the
    /// source mouth, over the rim, to the slot it lands in, while the destination's new
    /// top ball is held hidden so it reveals on landing (E14.3). Geometry comes from the
    /// captured tube frames (stable across a move) and the post-move destination count.
    private func startPourFlight(ballSize: CGFloat, ballGap: CGFloat, capacity: Int) {
        guard let move = model.lastMove, move.nonce != flight?.nonce,
              let sourceRect = tubeRects[move.from], let destRect = tubeRects[move.to],
              model.gameState.tubes.indices.contains(move.to) else { return }

        // The source already lost the ball, so its pre-move top sat one higher in the
        // count: launch from there so the ball lifts off exactly where it rested, not
        // from the mouth. The destination's new top is its current count.
        let sourceCountBeforeMove = model.gameState.tubes[move.from].count + 1
        let destCount = model.gameState.tubes[move.to].count
        let launch = PourGeometry.topBallPoint(
            in: sourceRect,
            capacity: capacity,
            count: sourceCountBeforeMove,
            ballSize: ballSize,
            ballGap: ballGap
        )
        let land = PourGeometry.topBallPoint(
            in: destRect,
            capacity: capacity,
            count: destCount,
            ballSize: ballSize,
            ballGap: ballGap
        )

        flight = PourFlight(
            nonce: move.nonce,
            launch: launch,
            land: land,
            color: move.color,
            peak: pourArcPeak(launch: launch, land: land, ballSize: ballSize)
        )
        suppressedTube = move.to
        flightProgress = 0
        withAnimation(AnimationConstants.pour) { flightProgress = 1 }

        // Clear the flight and reveal the landed ball when the arc finishes. Mirrors the
        // existing shake/flourish timer pattern; guarded so a newer flight isn't cut short.
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.pourDuration) {
            guard flight?.nonce == move.nonce else { return }
            flight = nil
            suppressedTube = nil
        }
    }

    /// How high the arc rises above its endpoints — enough to clear the rim, growing
    /// with the horizontal distance so far pours lift more. TUNABLE feel knob (E14.3).
    private func pourArcPeak(launch: CGPoint, land: CGPoint, ballSize: CGFloat) -> CGFloat {
        max(ballSize * 0.9, abs(land.x - launch.x) * 0.35)
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

/// Collects each tube's outer frame (keyed by tube index) for the pour-arc flight.
private struct TubeFramesKey: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
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
