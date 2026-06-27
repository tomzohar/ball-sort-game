import SwiftUI

/// Heads-up display for the active level: moves made, elapsed time, and how many
/// tubes are finished. A dumb view driven by plain values — `RootView` wraps it in
/// a `TimelineView` so `elapsed` ticks live.
///
/// Three stat pills sit on the raked-sand garden bed, styled in the Zen Garden
/// identity (E12): each pill is a raised `elevated` surface with a `stoneFrame`
/// hairline and a whisper of `rest` elevation. Values use the tabular `numeric`
/// token so the row never jitters as they change. Dumb styling only — renders the
/// passed values.
struct GameHUDView: View {
    let moves: Int
    let elapsed: TimeInterval
    let sortedCount: Int
    let tubeCount: Int

    var body: some View {
        HStack(spacing: ZenSpacing.md) {
            statPill("Moves", value: "\(moves)")
            statPill("Time", value: formatClock(elapsed))
            statPill("Sorted", value: "\(sortedCount)/\(tubeCount)")
        }
        .frame(maxWidth: .infinity)
    }

    /// A single rounded stat pill: a tabular numeric value over an uppercase caption
    /// label, on a raised `elevated` surface with a `stoneFrame` hairline border and
    /// the soft `rest` shadow.
    ///
    /// The label is a `LocalizedStringResource` so it localizes (E9.5); we resolve it
    /// to a `String` to apply `.uppercased()`, keeping the same uppercased styling.
    private func statPill(_ label: LocalizedStringResource, value: String) -> some View {
        VStack(spacing: ZenSpacing.xs) {
            Text(value)
                .font(ZenFont.numeric)
                .foregroundStyle(ZenColor.textPrimary)
            Text(String(localized: label).uppercased())
                .zenCaption()
                .foregroundStyle(ZenColor.textSecondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .padding(.vertical, ZenSpacing.sm)
        .padding(.horizontal, ZenSpacing.md)
        .background(pillBackground)
    }

    private var pillBackground: some View {
        let shape = RoundedRectangle(cornerRadius: ZenRadius.md, style: .continuous)
        return shape
            .fill(ZenColor.elevated)
            .overlay(
                shape.strokeBorder(ZenColor.stoneFrame, lineWidth: 1)
            )
            .zenShadow(.rest)
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
