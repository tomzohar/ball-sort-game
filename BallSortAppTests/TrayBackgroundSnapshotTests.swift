import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Targeted snapshot test for the wooden-tray container + dark backdrop visual primitives (ADR-0003).
/// Snapshots `host.view` at an explicit fixed frame so the baseline is device-independent
/// (the controller-level `.image` renders at the host window size, which differs across simulators).
final class TrayBackgroundSnapshotTests: XCTestCase {
    /// Fixed placeholder content so the snapshot is deterministic (no game logic).
    private var fixture: some View {
        ZStack {
            GameBackground()
            WoodenTray {
                HStack(spacing: 14) {
                    Circle().fill(Color(hex: 0xFFD21A))
                    Circle().fill(Color(hex: 0xFF7A18))
                    Circle().fill(Color(hex: 0x2196F3))
                    Circle().fill(Color(hex: 0x36D44A))
                }
                .frame(width: 220, height: 56)
            }
            .padding(40)
        }
        .frame(width: 390, height: 400)
    }

    func testWoodenTrayOverBackground() {
        let host = UIHostingController(rootView: fixture)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 400)

        // Snapshot the view at its fixed frame (not the controller, which renders at window size).
        // precision/perceptualPrecision absorb sub-pixel gradient-rendering diffs across OS versions.
        withSnapshotTesting(record: .missing) {
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
}
