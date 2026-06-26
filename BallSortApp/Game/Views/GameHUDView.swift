import SwiftUI

/// Heads-up display for the active level: moves made, elapsed time, and how many
/// tubes are finished. A dumb view driven by plain values — `RootView` wraps it in
/// a `TimelineView` so `elapsed` ticks live.
///
/// Foundation stub (E5): minimal layout; the polished HUD lands in the E5 fan-out.
struct GameHUDView: View {
    let moves: Int
    let elapsed: TimeInterval
    let sortedCount: Int
    let tubeCount: Int

    var body: some View {
        HStack(spacing: 24) {
            stat("Moves", "\(moves)")
            stat("Time", formatClock(elapsed))
            stat("Sorted", "\(sortedCount)/\(tubeCount)")
        }
        .foregroundStyle(.white)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
        }
    }
}
