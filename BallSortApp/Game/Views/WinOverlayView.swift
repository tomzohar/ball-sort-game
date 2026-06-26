import SwiftUI

/// The victory overlay shown when the level is solved: final moves/time and the
/// "next level" / "replay" actions. A dumb view driven by plain values and
/// callbacks; `RootView` decides when to present it.
///
/// Foundation stub (E5): minimal banner + buttons; the celebratory polish lands
/// in the E5 fan-out.
struct WinOverlayView: View {
    let moves: Int
    let elapsed: TimeInterval
    let onNextLevel: () -> Void
    let onReplay: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Solved!")
                .font(.largeTitle.bold())
            Text("\(moves) moves · \(formatClock(elapsed))")
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Button("Replay", action: onReplay)
                Button("Next Level", action: onNextLevel)
                    .buttonStyle(.borderedProminent)
            }
            .font(.headline)
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .transition(.scale.combined(with: .opacity))
    }
}
