import XCTest
import SnapshotTesting
import BallSortCore
import SwiftUI
@testable import BallSortApp

/// Visual-primitive snapshot tests for `DifficultyBadgeView` (ADR-0003).
///
/// Each band is rendered at a fixed frame over the dark warm backdrop so the baselines
/// are deterministic. Record once with `withSnapshotTesting(record: .all)`, commit the
/// PNGs under `__Snapshots__/`, then run un-recorded to confirm green.
final class DifficultyBadgeViewSnapshotTests: XCTestCase {
    /// Fixed frame for every baseline; wide enough for the longest "Level NN · Expert".
    private let width: CGFloat = 220
    private let height: CGFloat = 60

    /// Wraps a `DifficultyBadgeView` in a fixed-size, opaque container and snapshots it.
    private func assertBadge(
        level: Int,
        band: Difficulty.Band,
        named name: String,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let view = DifficultyBadgeView(level: level, band: band)
            .frame(width: width, height: height)
            .background(ZenColor.stage) // opaque Zen "stage" backdrop -> stable alpha

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
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

    func testEasyBand() {
        assertBadge(level: 1, band: .easy, named: "level1-easy")
    }

    func testExpertBand() {
        assertBadge(level: 9, band: .expert, named: "level9-expert")
    }

    func testRemainingBands() {
        assertBadge(level: 1, band: .trivial, named: "level1-trivial")
        assertBadge(level: 3, band: .medium, named: "level3-medium")
        assertBadge(level: 7, band: .hard, named: "level7-hard")
    }
}
