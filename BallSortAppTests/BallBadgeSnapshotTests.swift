import XCTest
import SnapshotTesting
import BallSortCore
import SwiftUI
@testable import BallSortApp

/// Snapshot test for the color-blind-safe SF Symbol badge on each ball (E9.4).
///
/// Mirrors `BallViewSnapshotTests`' harness exactly: a fixed-size, opaque container
/// rendered as an image so the badged baselines are deterministic. Record once with
/// `withSnapshotTesting(record: .all)`, commit the PNGs, then run un-recorded.
final class BallBadgeSnapshotTests: XCTestCase {
    /// Fixed diameter for every baseline.
    private let ballSize: CGFloat = 64
    /// Padding around the ball so the drop shadow isn't clipped.
    private let pad: CGFloat = 20

    private func assertBadgedBall(
        color: BallColor,
        named name: String,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let side = ballSize + pad * 2
        let view = BallView(color: color, size: ballSize, showsColorBlindBadge: true)
            .frame(width: side, height: side)
            .background(Color(white: 0.15)) // opaque backdrop -> stable alpha

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: side, height: side)
        host.view.backgroundColor = .clear

        withSnapshotTesting(record: .missing) {
            assertSnapshot(
                of: host.view,
                as: .image(precision: 0.98, traits: .init(userInterfaceStyle: .light)),
                named: name,
                file: file,
                testName: testName,
                line: line
            )
        }
    }

    func testAllColorsWithBadge() {
        for color in BallColor.allCases {
            assertBadgedBall(color: color, named: "\(color)")
        }
    }
}
