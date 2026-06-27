import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Visual snapshot test for `WinOverlayView` (ADR-0003).
///
/// The win overlay only appears mid-game (on win), so a running-app screenshot is
/// impractical — this snapshot is the required visual proof. Rendered at fixed
/// representative values over an opaque backdrop so the baseline is deterministic.
/// Record once with `withSnapshotTesting(record: .all)`, commit the PNG under
/// `__Snapshots__/`, then run un-recorded to confirm green.
final class WinOverlayViewSnapshotTests: XCTestCase {
    /// Fixed canvas large enough for the card plus its drop shadow.
    private let width: CGFloat = 360
    private let height: CGFloat = 460

    func testSolvedCard() {
        let view = ZStack {
            Color(white: 0.15) // opaque backdrop -> stable alpha
            WinOverlayView(
                moves: 18,
                elapsed: 95,
                startsSettled: true, // skip the entrance animation for a stable baseline
                onNextLevel: {},
                onReplay: {}
            )
        }
        .frame(width: width, height: height)

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        host.view.backgroundColor = .clear

        assertSnapshot(
            of: host.view,
            as: .image(precision: 0.98, perceptualPrecision: 0.97, traits: .init(userInterfaceStyle: .light)),
            named: "solved",
            testName: "WinOverlayView"
        )
    }
}
