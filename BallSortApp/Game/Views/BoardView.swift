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

    /// Bouncy spring approximating the prototype drop easing
    /// `cubic-bezier(.34, 1.4, .5, 1)` over ~0.28s.
    private var dropAnimation: Animation { .spring(response: 0.28, dampingFraction: 0.62) }

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
                    capacity: capacity,
                    ballSize: ballSize,
                    isSelected: model.isSelected(i),
                    isTarget: isTarget(i),
                    onTap: { withAnimation(dropAnimation) { model.tap(i) } }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: BoardWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(BoardWidthKey.self) { availableWidth = $0 }
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
