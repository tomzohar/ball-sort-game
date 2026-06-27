import XCTest
import SnapshotTesting
import SwiftUI
@testable import BallSortApp

/// Visual snapshot tests for `SettingsView` (ADR-0003).
///
/// The settings screen is a pure two-toggle form, so a snapshot is the practical
/// visual proof. Rendered at fixed size; the `@AppStorage` toggles read live from
/// `UserDefaults`, so each case seeds the standard defaults before hosting so the
/// baseline is deterministic. Record once with `withSnapshotTesting(record: .all)`,
/// commit the PNGs under `__Snapshots__/`, then run un-recorded to confirm green.
final class SettingsViewSnapshotTests: XCTestCase {
    /// Fixed canvas large enough for the title, toggle card, and Done button.
    private let width: CGFloat = 360
    private let height: CGFloat = 520

    func testBothEnabled() {
        UserDefaults.standard.set(true, forKey: "soundEnabled")
        UserDefaults.standard.set(true, forKey: "hapticsEnabled")
        defer {
            UserDefaults.standard.removeObject(forKey: "soundEnabled")
            UserDefaults.standard.removeObject(forKey: "hapticsEnabled")
        }

        let host = UIHostingController(rootView: SettingsView(onClose: {}))
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        host.view.backgroundColor = .clear

        assertSnapshot(
            of: host.view,
            as: .image(precision: 0.98, perceptualPrecision: 0.97, traits: .init(userInterfaceStyle: .light)),
            named: "both-enabled",
            testName: "SettingsView"
        )
    }

    func testBothDisabled() {
        UserDefaults.standard.set(false, forKey: "soundEnabled")
        UserDefaults.standard.set(false, forKey: "hapticsEnabled")
        defer {
            UserDefaults.standard.removeObject(forKey: "soundEnabled")
            UserDefaults.standard.removeObject(forKey: "hapticsEnabled")
        }

        let host = UIHostingController(rootView: SettingsView(onClose: {}))
        host.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        host.view.backgroundColor = .clear

        assertSnapshot(
            of: host.view,
            as: .image(precision: 0.98, perceptualPrecision: 0.97, traits: .init(userInterfaceStyle: .light)),
            named: "both-disabled",
            testName: "SettingsView"
        )
    }
}
