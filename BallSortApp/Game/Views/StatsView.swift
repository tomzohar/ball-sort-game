import SwiftUI

/// Player stats card: lifetime levels solved, the best (fewest-moves / fastest-time)
/// records, and the current/longest solving streak.
///
/// A dumb view (ADR-0001) driven by plain values — a later integration step maps the
/// real stats model in and decides *when* to present it. Record fields are optional:
/// a `nil` best-moves / best-time means "no record yet" and renders as an em dash.
///
/// Styled in the "Zen Garden" identity (E12.11): a light `elevated` card framed by a
/// `stoneFrame` hairline, each stat a `sandBed` pill with an uppercase `zenCaption`
/// label and a tabular `numeric` value. Tokens come from `ZenTheme` / `ZenTypography`
/// so the screen sits of-a-piece with the board, HUD, and overlays.
struct StatsView: View {
    let levelsSolved: Int
    let bestMoves: Int?
    let bestTimeSeconds: Double?
    let currentStreak: Int
    let longestStreak: Int

    /// Em dash shown when a record hasn't been set yet.
    private static var emptyRecord: String { "—" }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: ZenRadius.xl, style: .continuous)

        VStack(spacing: ZenSpacing.lg) {
            Text("Stats")
                .font(ZenFont.title)
                .foregroundStyle(ZenColor.textPrimary)

            VStack(spacing: ZenSpacing.sm) {
                statRow("Levels Solved", value: "\(levelsSolved)")
                statRow("Best Moves", value: bestMoves.map(String.init) ?? Self.emptyRecord)
                statRow(
                    "Best Time",
                    value: bestTimeSeconds.map(formatClock) ?? Self.emptyRecord
                )
                statRow("Current Streak", value: "\(currentStreak)")
                statRow("Longest Streak", value: "\(longestStreak)")
            }
        }
        .padding(ZenSpacing.xl)
        .frame(maxWidth: 320)
        .background(ZenColor.elevated, in: shape)
        .overlay(
            shape.strokeBorder(ZenColor.stoneFrame, lineWidth: 1)
                .allowsHitTesting(false)
        )
        .zenShadow(.modal)
    }

    /// A labelled stat row rendered as a Zen pill: uppercase caption label on the left,
    /// tabular numeric value on the right, on a `sandBed` surface.
    ///
    /// The label is a `LocalizedStringResource` so it localizes (E9.5); we resolve it
    /// to a `String` to apply `.uppercased()`, keeping the same uppercased styling.
    private func statRow(_ label: LocalizedStringResource, value: String) -> some View {
        HStack {
            Text(String(localized: label).uppercased())
                .zenCaption()
                .foregroundStyle(ZenColor.textSecondary)
            Spacer(minLength: ZenSpacing.md)
            Text(value)
                .font(ZenFont.numeric)
                .foregroundStyle(ZenColor.textPrimary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.vertical, ZenSpacing.md)
        .padding(.horizontal, ZenSpacing.lg)
        .background(
            ZenColor.sandBed,
            in: RoundedRectangle(cornerRadius: ZenRadius.md, style: .continuous)
        )
    }
}

#Preview("Populated") {
    ZStack {
        ZenColor.stage.ignoresSafeArea()
        StatsView(
            levelsSolved: 42,
            bestMoves: 14,
            bestTimeSeconds: 73,
            currentStreak: 5,
            longestStreak: 12
        )
    }
}

#Preview("Empty records") {
    ZStack {
        ZenColor.stage.ignoresSafeArea()
        StatsView(
            levelsSolved: 0,
            bestMoves: nil,
            bestTimeSeconds: nil,
            currentStreak: 0,
            longestStreak: 0
        )
    }
}
