import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Visual snapshot tests for `StatsView` (ADR-0003).
///
/// The stats screen is value-driven, so snapshots are the practical visual proof.
/// Rendered at fixed representative values over an opaque backdrop so the baseline is
/// deterministic and device-independent. Two states: a populated card and one with
/// no records yet (the em-dash fallback). Record once with
/// `withSnapshotTesting(record: .all)`, commit the PNGs under `__Snapshots__/`, then
/// run un-recorded to confirm green.
final class StatsViewSnapshotTests: XCTestCase {
    /// Fixed canvas large enough for the card plus its drop shadow.
    private let width: CGFloat = 360
    private let height: CGFloat = 520

    func testPopulated() {
        let view = fixture(
            StatsView(
                levelsSolved: 42,
                bestMoves: 14,
                bestTimeSeconds: 73,
                currentStreak: 5,
                longestStreak: 12
            )
        )

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        host.view.backgroundColor = .clear

        assertSnapshot(
            of: host.view,
            as: .image(precision: 0.98, perceptualPrecision: 0.97, traits: .init(userInterfaceStyle: .light)),
            named: "populated",
            testName: "StatsView"
        )
    }

    func testEmptyRecords() {
        let view = fixture(
            StatsView(
                levelsSolved: 0,
                bestMoves: nil,
                bestTimeSeconds: nil,
                currentStreak: 0,
                longestStreak: 0
            )
        )

        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        host.view.backgroundColor = .clear

        assertSnapshot(
            of: host.view,
            as: .image(precision: 0.98, perceptualPrecision: 0.97, traits: .init(userInterfaceStyle: .light)),
            named: "empty",
            testName: "StatsView"
        )
    }

    private func fixture(_ stats: StatsView) -> some View {
        ZStack {
            Color(white: 0.15) // opaque backdrop -> stable alpha
            stats
        }
        .frame(width: width, height: height)
    }
}
