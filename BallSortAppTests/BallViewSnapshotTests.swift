import XCTest
import SnapshotTesting
import BallSortCore
import SwiftUI
@testable import BallSortApp

/// Visual-primitive snapshot tests for `BallView` (ADR-0003).
///
/// Each `BallColor` and the lifted state are rendered at a fixed size and scale so
/// the baselines are deterministic. Record once with `withSnapshotTesting(record: .all)`,
/// commit the PNGs under `__Snapshots__/`, then run un-recorded to confirm green.
final class BallViewSnapshotTests: XCTestCase {
    /// Fixed diameter for every baseline.
    private let ballSize: CGFloat = 64
    /// Padding around the ball so the drop shadow / lift glow aren't clipped.
    private let pad: CGFloat = 20

    /// Wraps a `BallView` in a fixed-size, opaque container and snapshots it as an image.
    private func assertBall(
        color: BallColor,
        isLifted: Bool,
        named name: String,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let side = ballSize + pad * 2
        let view = BallView(color: color, size: ballSize, isLifted: isLifted)
            .frame(width: side, height: side)
            .background(Color(white: 0.15)) // opaque backdrop -> stable alpha

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: side, height: side)
        host.view.backgroundColor = .clear

        assertSnapshot(
            of: host.view,
            as: .image(precision: 0.98, traits: .init(userInterfaceStyle: .light)),
            named: name,
            file: file,
            testName: testName,
            line: line
        )
    }

    func testAllColors() {
        for color in BallColor.allCases {
            assertBall(color: color, isLifted: false, named: "\(color)")
        }
    }

    func testLifted() {
        assertBall(color: .blue, isLifted: true, named: "blue-lifted")
    }
}
