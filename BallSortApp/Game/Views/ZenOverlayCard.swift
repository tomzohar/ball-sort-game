import SwiftUI

// Shared "Zen Garden" overlay-card surface (E12.10), used by both the win overlay
// and the generating/loading overlay so the two modal moments feel of-a-piece.
// Dumb styling only — no game logic (ADR-0001).

/// Wraps arbitrary `content` in the Zen overlay-card look: an elevated frosted
/// surface, a hairline stone frame, a soft modal shadow, and a generous radius.
///
/// The dimmed scrim behind the card is owned by the presenter (`RootView`), matching
/// the existing pattern; this view is just the card itself.
struct ZenOverlayCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: ZenRadius.xl, style: .continuous)

        content
            .padding(ZenSpacing.xl)
            .frame(maxWidth: 320)
            .background(ZenColor.elevated, in: shape)
            .overlay(
                shape
                    .strokeBorder(ZenColor.stoneFrame, lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .zenShadow(ZenShadow.modal)
    }
}

#Preview {
    ZStack {
        Color(white: 0.4).ignoresSafeArea()
        ZenOverlayCard {
            VStack(spacing: ZenSpacing.md) {
                Text("Solved!").font(ZenFont.display).foregroundStyle(ZenColor.textPrimary)
                Text("a calm card").font(ZenFont.caption).foregroundStyle(ZenColor.textSecondary)
            }
        }
    }
}
