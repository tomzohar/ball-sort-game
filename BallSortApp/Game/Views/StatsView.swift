import SwiftUI

/// Player stats card: lifetime levels solved, the best (fewest-moves / fastest-time)
/// records, and the current/longest solving streak.
///
/// A dumb view (ADR-0001) driven by plain values — a later integration step maps the
/// real stats model in and decides *when* to present it. Record fields are optional:
/// a `nil` best-moves / best-time means "no record yet" and renders as an em dash.
///
/// Styling borrows the prototype's wooden-tray theme (warm gradient card, dark border,
/// glossy top highlight) so the screen sits of-a-piece with the board and win overlay
/// (PROJECT_BRIEF, m3). Numbers use monospaced digits to match the HUD.
struct StatsView: View {
    let levelsSolved: Int
    let bestMoves: Int?
    let bestTimeSeconds: Double?
    let currentStreak: Int
    let longestStreak: Int

    private static var cornerRadius: CGFloat { 24 }

    /// Em dash shown when a record hasn't been set yet.
    private static var emptyRecord: String { "—" }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)

        VStack(spacing: 18) {
            Text("Stats")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)

            VStack(spacing: 10) {
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
        .padding(28)
        .frame(maxWidth: 320)
        .background(cardBackground(shape: shape))
        .overlay(
            shape.strokeBorder(Color(hex: 0x5E3C1C), lineWidth: 5)
                .allowsHitTesting(false)
        )
        .shadow(color: .black.opacity(0.55), radius: 24, x: 0, y: 18)
    }

    /// A labelled stat row: caption-style label on the left, monospaced value on the
    /// right, on a translucent dark capsule echoing the HUD pills.
    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.7))
            Spacer(minLength: 12)
            Text(value)
                .font(.title3.bold().monospacedDigit())
                .foregroundStyle(.white)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            Color.black.opacity(0.18),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }

    /// Warm wooden gradient with a glossy top highlight, mirroring `WoodenTray`.
    private func cardBackground(shape: RoundedRectangle) -> some View {
        LinearGradient(
            colors: [Color(hex: 0xC98A4B), Color(hex: 0x8A5A2B)],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            LinearGradient(
                colors: [Color.white.opacity(0.28), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .allowsHitTesting(false)
        )
        .clipShape(shape)
    }
}

#Preview("Populated") {
    ZStack {
        GameBackground()
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
        GameBackground()
        StatsView(
            levelsSolved: 0,
            bestMoves: nil,
            bestTimeSeconds: nil,
            currentStreak: 0,
            longestStreak: 0
        )
    }
}
