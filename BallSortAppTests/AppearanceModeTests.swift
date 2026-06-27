import XCTest
import SwiftUI
@testable import BallSortApp

/// Unit tests for `AppearanceMode` — the persisted light/dark preference.
///
/// The enum is the single mapping between the stored raw string (written by
/// `SettingsView`, read by the app root) and the `ColorScheme?` handed to
/// `.preferredColorScheme`. These pin that contract: stable raw values (so persisted
/// choices survive upgrades), the system→nil / light→.light / dark→.dark mapping the
/// root relies on, and the `.system` fallback for absent/garbage stored values.
final class AppearanceModeTests: XCTestCase {
    /// Raw values are the persistence contract — they must stay stable so a value
    /// stored by an old build still resolves after an update.
    func testRawValuesAreStable() {
        XCTAssertEqual(AppearanceMode.system.rawValue, "system")
        XCTAssertEqual(AppearanceMode.light.rawValue, "light")
        XCTAssertEqual(AppearanceMode.dark.rawValue, "dark")
    }

    /// The default appearance follows the device, which `.preferredColorScheme(nil)`
    /// expresses.
    func testSystemMapsToNilColorScheme() {
        XCTAssertNil(AppearanceMode.system.colorScheme)
    }

    /// Light/Dark force the matching scheme app-wide.
    func testLightAndDarkForceTheirScheme() {
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }

    /// A recognized stored value resolves to its mode.
    func testStoredValueResolvesKnownModes() {
        XCTAssertEqual(AppearanceMode(storedValue: "light"), .light)
        XCTAssertEqual(AppearanceMode(storedValue: "dark"), .dark)
        XCTAssertEqual(AppearanceMode(storedValue: "system"), .system)
    }

    /// An absent or unrecognized stored value falls back to `.system` rather than
    /// crashing or forcing a scheme.
    func testStoredValueFallsBackToSystem() {
        XCTAssertEqual(AppearanceMode(storedValue: ""), .system)
        XCTAssertEqual(AppearanceMode(storedValue: "sepia"), .system)
    }

    /// The picker iterates all three cases in the documented order.
    func testAllCasesArePresentedInOrder() {
        XCTAssertEqual(AppearanceMode.allCases, [.system, .light, .dark])
    }
}
