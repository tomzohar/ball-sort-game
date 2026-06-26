import XCTest
import SnapshotTesting
import SwiftUI
import BallSortCore
@testable import BallSortApp

/// Targeted snapshot test for the assembled board (tubes in the wooden tray over
/// the backdrop) — the E4.6 visual primitive (ADR-0003).
///
/// Snapshots `host.view` at an explicit fixed frame so the baseline is
/// device-independent; precision/perceptualPrecision absorb sub-pixel gradient
/// rendering diffs across OS versions.
@MainActor
final class BoardViewSnapshotTests: XCTestCase {
    /// A fixed, mid-game 6-tube board (4 colors + 2 empty) so the snapshot is
    /// deterministic and exercises filled, partially filled, and empty tubes.
    private var fixtureState: GameState {
        GameState(
            tubes: [
                Tube(balls: [.blue, .pink, .green, .yellow], capacity: 4),
                Tube(balls: [.yellow, .green, .pink], capacity: 4),
                Tube(balls: [.green, .blue, .yellow, .pink], capacity: 4),
                Tube(balls: [.pink, .yellow, .blue], capacity: 4),
                Tube(balls: [.blue, .green], capacity: 4),
                Tube(balls: [], capacity: 4)
            ],
            capacity: 4
        )
    }

    private var fixture: some View {
        ZStack {
            GameBackground()
            WoodenTray { BoardView(model: BoardViewModel(initialState: fixtureState)) }
                .padding(16)
        }
        .frame(width: 390, height: 360)
    }

    func testBoardInWoodenTray() {
        let host = UIHostingController(rootView: fixture)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 360)

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
