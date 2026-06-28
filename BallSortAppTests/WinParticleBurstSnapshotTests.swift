import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Visual snapshot test for `WinParticleBurst` (ADR-0003).
///
/// The bloom only plays mid-game on a win, so a running-app screenshot is impractical
/// — this is the required visual proof. `settled: true` freezes a deterministic
/// mid-bloom frame (particle positions/colours are derived from the index, no
/// randomness), so the baseline is stable. Record once with
/// `withSnapshotTesting(record: .all)`, commit the PNG under `__Snapshots__/`, then
/// run un-recorded to confirm green.
final class WinParticleBurstSnapshotTests: XCTestCase {
    /// Square canvas centred on the bloom, large enough for its full reach.
    private let side: CGFloat = 360

    func testBloom() {
        let view = ZStack {
            Color(white: 0.15) // opaque backdrop -> stable alpha
            WinParticleBurst(settled: true)
        }
        .frame(width: side, height: side)

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: side, height: side)
        host.view.backgroundColor = .clear

        assertSnapshot(
            of: host.view,
            as: .image(precision: 0.98, perceptualPrecision: 0.97, traits: .init(userInterfaceStyle: .light)),
            named: "bloom",
            testName: "WinParticleBurst"
        )
    }
}
