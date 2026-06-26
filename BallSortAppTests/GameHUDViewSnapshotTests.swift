import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Targeted snapshot test for the `GameHUDView` stat row (ADR-0003).
/// Rendered over the game backdrop at an explicit fixed frame so the baseline is
/// device-independent. precision/perceptualPrecision absorb sub-pixel gradient diffs
/// across OS versions (same tolerances as the other visual-primitive snapshots).
final class GameHUDViewSnapshotTests: XCTestCase {
    private let width: CGFloat = 390
    private let height: CGFloat = 120

    private var fixture: some View {
        ZStack {
            GameBackground()
            GameHUDView(moves: 12, elapsed: 83, sortedCount: 2, tubeCount: 6)
                .padding(.horizontal, 20)
        }
        .frame(width: width, height: height)
    }

    func testGameHUD() {
        let host = UIHostingController(rootView: fixture)
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)

        assertSnapshot(
            of: host.view,
            as: .image(
                precision: 0.98,
                perceptualPrecision: 0.97,
                traits: .init(userInterfaceStyle: .light)
            )
        )
    }
}
