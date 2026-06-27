import Observation

/// Drives the first-run tutorial's step progression (E14.2). Pure presentation
/// state — no SwiftUI, no persistence — so every transition is unit-testable. The
/// view writes the `Tutorial.hasSeenKey` flag when `isFinished` flips to `true`.
@Observable
final class TutorialViewModel {
    /// The ordered steps being shown. Guaranteed non-empty.
    let steps: [TutorialStep]
    /// Index of the step currently on screen.
    private(set) var index: Int = 0
    /// Becomes `true` once the player finishes the last step or skips. Terminal —
    /// the view dismisses the overlay and records that the tutorial was seen.
    private(set) var isFinished = false

    init(steps: [TutorialStep] = Tutorial.steps) {
        precondition(!steps.isEmpty, "the tutorial needs at least one step")
        self.steps = steps
    }

    /// The step currently on screen.
    var currentStep: TutorialStep { steps[index] }

    /// Whether the current step is the first / last in the sequence.
    var isFirstStep: Bool { index == 0 }
    var isLastStep: Bool { index == steps.count - 1 }

    /// 1-based position for the step indicator ("2 of 3").
    var stepNumber: Int { index + 1 }
    var stepCount: Int { steps.count }

    /// Advance to the next step, or finish if already on the last one. This is the
    /// primary ("Next" / "Got it") action.
    func advance() {
        guard !isFinished else { return }
        if isLastStep {
            isFinished = true
        } else {
            index += 1
        }
    }

    /// Step back toward the start; a no-op on the first step.
    func back() {
        guard !isFinished, !isFirstStep else { return }
        index -= 1
    }

    /// Dismiss the whole tutorial immediately from any step ("Skip").
    func skip() {
        isFinished = true
    }
}
