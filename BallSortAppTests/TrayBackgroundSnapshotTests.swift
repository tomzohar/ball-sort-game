import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Targeted snapshot test for the wooden-tray container + dark backdrop visual primitives (ADR-0003).
/// Baselines are pinned to the iPhone 17 Pro simulator on the CI runner; record intentionally.
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

        assertSnapshot(of: host, as: .image)
    }
}
