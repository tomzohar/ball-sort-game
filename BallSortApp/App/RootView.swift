import SwiftUI
import BallSortCore

/// The game screen: the wooden tray + board over the dark backdrop, with a
/// minimal moves/restart bar. The full HUD (time, sorted count) and win overlay
/// land in E5; this screen exists so the E4 board is playable end to end.
struct RootView: View {
    /// The board state machine, injected by the composition root.
    let model: BoardViewModel

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 20) {
                header
                WoodenTray { BoardView(model: model) }
                    .padding(.horizontal, 12)
                Spacer(minLength: 0)
            }
            .padding(.top, 12)

            if model.isWon {
                wonBanner
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Moves: \(model.moveCount)")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            Button("Restart") {
                withAnimation(.easeInOut) { model.restart() }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.15), in: Capsule())
        }
        .padding(.horizontal, 20)
    }

    private var wonBanner: some View {
        Text("Solved!")
            .font(.largeTitle.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .transition(.scale.combined(with: .opacity))
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
    return RootView(model: BoardViewModel(initialState: state))
}
