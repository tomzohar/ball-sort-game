import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Targeted snapshot tests for the first-run tutorial overlay (E14.2): the opening
/// step (with "Next" + "Skip") and the final step (with "Got It" and Skip hidden).
///
/// Rendered settled (`startsSettled: true`) over an opaque backdrop at a fixed frame
/// so the baseline is device- and animation-independent. This is custom-drawn Zen
/// content (card, symbol, step dots, pill buttons) — the kind ADR-0003 says to
/// snapshot — not a system control.
@MainActor
final class TutorialOverlayViewSnapshotTests: XCTestCase {

    private func host(_ model: TutorialViewModel) -> UIView {
        let view = ZStack {
            GameBackground()
            ZenColor.scrim.ignoresSafeArea()
            TutorialOverlayView(model: model, startsSettled: true, onFinish: {})
        }
        .frame(width: 390, height: 500)

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 500)
        return host.view
    }

    func testFirstStep() {
        withSnapshotTesting(record: .missing) {
            assertSnapshot(
                of: host(TutorialViewModel()),
                as: .image(
                    precision: 0.98,
                    perceptualPrecision: 0.97,
                    traits: .init(userInterfaceStyle: .light)
                )
            )
        }
    }

    func testLastStep() {
        let model = TutorialViewModel()
        model.advance()
        model.advance() // walk to the final step

        withSnapshotTesting(record: .missing) {
            assertSnapshot(
                of: host(model),
                as: .image(
                    precision: 0.98,
                    perceptualPrecision: 0.97,
                    traits: .init(userInterfaceStyle: .light)
                )
            )
        }
    }
}
