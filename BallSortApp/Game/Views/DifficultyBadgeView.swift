import SwiftUI
import BallSortCore

/// A small pill showing the current level number and its difficulty band. A dumb
/// view driven by plain values.
///
/// Foundation stub (E5): minimal pill; the polished styling lands in the E5
/// fan-out.
struct DifficultyBadgeView: View {
    let level: Int
    let band: Difficulty.Band

    var body: some View {
        Text("Level \(level) · \(label)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.15), in: Capsule())
    }

    private var label: String {
        switch band {
        case .trivial: return "Trivial"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
}
