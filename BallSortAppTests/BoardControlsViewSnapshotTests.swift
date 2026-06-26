import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Visual-primitive snapshot tests for `BoardControlsView` (ADR-0003).
///
/// Snapshots both `canUndo` states over the dark backdrop so the disabled (dimmed,
/// desaturated) Undo styling is captured. Closures are no-ops — this is a dumb view.
/// Record once with `withSnapshotTesting(record: .all)`, commit the PNGs under
/// `__Snapshots__/`, then run un-recorded to confirm green.
final class BoardControlsViewSnapshotTests: XCTestCase {
    /// Fixed frame so the baseline is device-independent (the controller-level
    /// `.image` otherwise renders at the host window size, which varies per simulator).
    private let width: CGFloat = 390
    private let height: CGFloat = 140

    private func assertControls(
        canUndo: Bool,
        named name: String,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let view = ZStack {
            GameBackground()
            BoardControlsView(canUndo: canUndo, onUndo: {}, onRestart: {})
        }
        .frame(width: width, height: height)

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)

        // precision/perceptualPrecision absorb sub-pixel gradient-rendering diffs across OS versions.
        assertSnapshot(
            of: host.view,
            as: .image(
                precision: 0.98,
                perceptualPrecision: 0.97,
                traits: .init(userInterfaceStyle: .light)
            ),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }

    func testCanUndoEnabled() {
        assertControls(canUndo: true, named: "can-undo")
    }

    func testCanUndoDisabled() {
        assertControls(canUndo: false, named: "cannot-undo")
    }
}
