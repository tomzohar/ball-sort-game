import SwiftUI

/// Heads-up display for the active level: moves made, elapsed time, and how many
/// tubes are finished. A dumb view driven by plain values — `RootView` wraps it in
/// a `TimelineView` so `elapsed` ticks live.
///
/// Three stat pills sit on the dark warm backdrop, styled to match the prototype's
/// wooden-tray theme (PROJECT_BRIEF, m3). Numbers use monospaced digits so the row
/// doesn't jitter as values change. Dumb styling only — renders the passed values.
struct GameHUDView: View {
    let moves: Int
    let elapsed: TimeInterval
    let sortedCount: Int
    let tubeCount: Int

    var body: some View {
        HStack(spacing: 10) {
            statPill("Moves", value: "\(moves)")
            statPill("Time", value: formatClock(elapsed))
            statPill("Sorted", value: "\(sortedCount)/\(tubeCount)")
        }
        .frame(maxWidth: .infinity)
    }

    /// A single rounded stat pill: large monospaced value over an uppercase label,
    /// on a translucent dark capsule with a thin warm border and soft drop shadow.
    ///
    /// The label is a `LocalizedStringResource` so it localizes (E9.5); we resolve it
    /// to a `String` to apply `.uppercased()`, keeping the same uppercased styling.
    private func statPill(_ label: LocalizedStringResource, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
            Text(String(localized: label).uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.6))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(pillBackground)
    }

    private var pillBackground: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return shape
            .fill(Color.black.opacity(0.28))
            // Subtle top highlight so the pill reads as raised, echoing the tray.
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.10), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(shape)
                .allowsHitTesting(false)
            )
            .overlay(
                shape.strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    ZStack {
        GameBackground()
        VStack {
            GameHUDView(moves: 12, elapsed: 83, sortedCount: 2, tubeCount: 6)
                .padding(.horizontal, 20)
            Spacer()
        }
        .padding(.top, 24)
    }
}
