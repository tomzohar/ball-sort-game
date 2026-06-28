import SwiftUI
import BallSortCore

/// A calm one-shot particle bloom shown behind the win card (E14.5): a ring of small
/// river-stone–toned dots that drift outward and fade, so victory *lands* without
/// breaking the Zen Garden's quiet motion language. Purely decorative.
///
/// Dumb + deterministic (ADR-0001): every particle's angle, reach, size, and colour is
/// derived from its index — no randomness — so the bloom is identical run-to-run and
/// snapshot-stable. `settled` freezes it at a representative mid-bloom frame for
/// snapshots/previews. Honours **Reduce Motion** by rendering nothing; the win card's
/// own entrance carries the moment in that case.
struct WinParticleBurst: View {
    /// Snapshot/preview hook: render a fixed mid-bloom frame instead of animating in.
    var settled: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 0 = every particle at the centre, 1 = fully dispersed and faded out.
    @State private var progress: CGFloat

    init(settled: Bool = false) {
        self.settled = settled
        _progress = State(initialValue: settled ? Self.settledFrame : 0)
    }

    /// Number of particles in the bloom.
    private static let count = 22

    /// The progress frame `settled` freezes on: dispersed enough to read, still visible.
    private static let settledFrame: CGFloat = 0.55

    /// The 6-stone river-stone palette (matches the balls) cycled across particles, so
    /// the bloom is recognisably "of" this game rather than generic confetti.
    private static let palette: [Color] = [
        BallColor.yellow, .orange, .pink, .green, .blue, .purple
    ].map(\.swiftUIColor)

    var body: some View {
        // Reduce Motion: no flying particles. The win card's entrance marks the win.
        if reduceMotion {
            Color.clear
        } else {
            ZStack {
                ForEach(0..<Self.count, id: \.self) { i in
                    dot(i)
                }
            }
            .allowsHitTesting(false)
            .onAppear {
                guard !settled else { return }
                withAnimation(AnimationConstants.winBurst) { progress = 1 }
            }
        }
    }

    /// A deterministic per-particle spec, derived purely from the index.
    private struct ParticleSpec {
        let angle: CGFloat
        let reach: CGFloat
        let size: CGFloat
        let color: Color
    }

    /// A single particle, blooming out along its angle and fading as it disperses.
    private func dot(_ i: Int) -> some View {
        let spec = Self.spec(for: i)
        return Circle()
            .fill(spec.color)
            .frame(width: spec.size, height: spec.size)
            // Drift outward along the particle's angle, with a gentle gravity sag near
            // the end (progress²) so the bloom eases into a soft fall rather than a flat ring.
            .offset(
                x: cos(spec.angle) * spec.reach * progress,
                y: sin(spec.angle) * spec.reach * progress + Self.gravity * progress * progress
            )
            // Pop from a seed to full size as it leaves the centre, then hold.
            .scaleEffect(0.4 + 0.6 * min(1, progress * 3))
            .opacity(Double(1 - progress))
    }

    /// Downward drift (pt) applied as progress², so particles ease into a gentle fall.
    private static let gravity: CGFloat = 26

    /// Deterministic per-particle spec from the index — no randomness, so the bloom is
    /// snapshot-stable. Three reach/size bands give the ring depth instead of one clean
    /// circle; a half-step angular offset on alternating particles breaks the regularity.
    private static func spec(for i: Int) -> ParticleSpec {
        let n = CGFloat(count)
        let angle = (CGFloat(i) / n) * 2 * .pi + (i % 2 == 0 ? 0 : .pi / n)
        return ParticleSpec(
            angle: angle,
            reach: [120, 150, 95][i % 3],
            size: [10, 7, 13][i % 3],
            color: palette[i % palette.count]
        )
    }
}

#Preview {
    ZStack {
        GameBackground()
        ZenColor.scrim.ignoresSafeArea()
        WinParticleBurst(settled: true)
    }
}
