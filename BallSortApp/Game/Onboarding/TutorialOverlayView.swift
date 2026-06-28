import SwiftUI

/// The first-run tutorial overlay (E14.2): a calm Zen-Garden card stepping through
/// the short walkthrough, shown once over the board on first launch and replayable
/// from Settings.
///
/// A dumb view (ADR-0001): it renders `TutorialViewModel` state and routes the
/// primary/skip actions back to it, calling `onFinish` when the model reaches its
/// terminal state. `RootView` owns the dimmed scrim and decides *when* to present it.
/// Reuses the shared `ZenOverlayCard` surface so onboarding feels of-a-piece with the
/// win and loading overlays.
struct TutorialOverlayView: View {
    @State private var model: TutorialViewModel
    /// Called when the player finishes the last step or skips — the host records that
    /// the tutorial was seen and dismisses the overlay.
    private let onFinish: () -> Void

    /// When `true`, renders settled (no entrance animation) for stable snapshots.
    private let startsSettled: Bool
    @State private var appeared: Bool

    init(
        model: TutorialViewModel = TutorialViewModel(),
        startsSettled: Bool = false,
        onFinish: @escaping () -> Void
    ) {
        _model = State(initialValue: model)
        self.onFinish = onFinish
        self.startsSettled = startsSettled
        _appeared = State(initialValue: startsSettled)
    }

    var body: some View {
        ZenOverlayCard {
            VStack(spacing: ZenSpacing.lg) {
                Image(systemName: model.currentStep.symbol)
                    .font(.system(size: 44))
                    .foregroundStyle(ZenColor.accent)
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 52)
                    .accessibilityHidden(true)

                VStack(spacing: ZenSpacing.sm) {
                    Text(model.currentStep.title)
                        .font(ZenFont.display)
                        .foregroundStyle(ZenColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(model.currentStep.message)
                        .font(ZenFont.body)
                        .foregroundStyle(ZenColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                // Re-key on the step so the copy cross-fades as the player advances.
                .id(model.index)
                .transition(.opacity)

                stepIndicator

                buttons
                    .padding(.top, ZenSpacing.xs)
            }
            .frame(minHeight: 232, alignment: .top)
        }
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.9)
        .animation(AnimationConstants.winCelebration, value: appeared)
        .transition(.scale.combined(with: .opacity))
        .onAppear { appeared = true }
    }

    /// A row of dots, the current step filled — a lightweight "x of n" affordance.
    private var stepIndicator: some View {
        HStack(spacing: ZenSpacing.sm) {
            ForEach(model.steps) { step in
                Circle()
                    .fill(step.id == model.currentStep.id ? ZenColor.accent : ZenColor.stoneFrame)
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityLabel("Step \(model.stepNumber) of \(model.stepCount)")
    }

    /// Primary "Next"/"Got it" over a quiet "Skip".
    private var buttons: some View {
        VStack(spacing: ZenSpacing.sm) {
            Button {
                withAnimation(.easeInOut) { model.advance() }
                if model.isFinished { onFinish() }
            } label: {
                Text(model.isLastStep ? "Got It" : "Next")
                    .font(ZenFont.button)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(ZenColor.accent)

            Button {
                model.skip()
                onFinish()
            } label: {
                Text("Skip")
                    .font(ZenFont.button)
                    .foregroundStyle(ZenColor.textSecondary)
            }
            .buttonStyle(.plain)
            .opacity(model.isLastStep ? 0 : 1)
            .accessibilityHidden(model.isLastStep)
        }
    }
}

#Preview {
    ZStack {
        GameBackground()
        ZenColor.scrim.ignoresSafeArea()
        TutorialOverlayView(startsSettled: true, onFinish: {})
    }
}
