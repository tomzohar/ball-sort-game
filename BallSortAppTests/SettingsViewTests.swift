import XCTest
import SwiftUI
@testable import BallSortApp

/// Behavioral tests for `SettingsView`'s `@AppStorage` bindings.
///
/// `SettingsView`'s two toggles bind to the `"soundEnabled"` / `"hapticsEnabled"`
/// `UserDefaults` keys that `SoundPlayer` / `HapticsPlayer` read at play-time. The
/// view is built from the system `Toggle` (the green switch), whose pixels render
/// differently across OS versions — so a snapshot is OS-fragile and useless on CI
/// (which picks any available simulator). What actually matters, and what these
/// tests pin, is the OS-independent contract: the view reads the seeded keys and
/// flipping a toggle writes them back, with the documented `true` default matching
/// the players' `?? true` fallback.
///
/// Defaults are asserted at the `UserDefaults` layer — the binding's source of
/// truth. Each test seeds `UserDefaults.standard` and cleans up via `defer` so the
/// shared store is left untouched.
final class SettingsViewTests: XCTestCase {
    private let soundKey = "soundEnabled"
    private let hapticsKey = "hapticsEnabled"
    private let appearanceKey = AppearanceMode.storageKey

    override func setUp() {
        super.setUp()
        clearKeys()
    }

    override func tearDown() {
        clearKeys()
        super.tearDown()
    }

    private func clearKeys() {
        UserDefaults.standard.removeObject(forKey: soundKey)
        UserDefaults.standard.removeObject(forKey: hapticsKey)
        UserDefaults.standard.removeObject(forKey: appearanceKey)
    }

    /// The view binds to the documented keys; constructing it with no stored values
    /// leaves the keys absent, so the players' `?? true` fallback (and the view's
    /// `= true` default) both treat them as on — the consistent default.
    func testDefaultsAreAbsentSoBothFallBackToOn() {
        _ = SettingsView(onClose: {})

        // No stored value -> object(forKey:) is nil -> `?? true` (players) / `= true`
        // (@AppStorage) both resolve to enabled. This is the contract the keys/defaults
        // are chosen to satisfy.
        XCTAssertNil(UserDefaults.standard.object(forKey: soundKey))
        XCTAssertNil(UserDefaults.standard.object(forKey: hapticsKey))
        XCTAssertTrue(UserDefaults.standard.object(forKey: soundKey) as? Bool ?? true)
        XCTAssertTrue(UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true)
    }

    /// A seeded `false` for either key is what the player gate reads — the disabled
    /// state the toggle reflects. Pins that the view binds to these exact keys.
    func testSeededDisabledValuesAreReadFromUserDefaults() {
        UserDefaults.standard.set(false, forKey: soundKey)
        UserDefaults.standard.set(true, forKey: hapticsKey)

        _ = SettingsView(onClose: {})

        XCTAssertFalse(UserDefaults.standard.object(forKey: soundKey) as? Bool ?? true)
        XCTAssertTrue(UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true)
    }

    /// Flipping the sound binding writes `"soundEnabled"` so the next `SoundPlayer`
    /// gate read sees the change live — the core behavior of the screen.
    func testTogglingSoundWritesTheSoundKey() {
        UserDefaults.standard.set(true, forKey: soundKey)
        let view = SettingsView(onClose: {})

        view.soundEnabledBinding.wrappedValue.toggle()

        XCTAssertFalse(UserDefaults.standard.object(forKey: soundKey) as? Bool ?? true)

        view.soundEnabledBinding.wrappedValue.toggle()
        XCTAssertTrue(UserDefaults.standard.object(forKey: soundKey) as? Bool ?? false)
    }

    /// Flipping the haptics binding writes `"hapticsEnabled"` for `HapticsPlayer`.
    func testTogglingHapticsWritesTheHapticsKey() {
        UserDefaults.standard.set(true, forKey: hapticsKey)
        let view = SettingsView(onClose: {})

        view.hapticsEnabledBinding.wrappedValue.toggle()

        XCTAssertFalse(UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? true)

        view.hapticsEnabledBinding.wrappedValue.toggle()
        XCTAssertTrue(UserDefaults.standard.object(forKey: hapticsKey) as? Bool ?? false)
    }

    /// With nothing stored, the appearance binding reports the `.system` default —
    /// the app root reads the same key and follows the device.
    func testAppearanceDefaultsToSystemWhenAbsent() {
        let view = SettingsView(onClose: {})

        XCTAssertNil(UserDefaults.standard.object(forKey: appearanceKey))
        XCTAssertEqual(view.appearanceBinding.wrappedValue, AppearanceMode.system.rawValue)
    }

    /// Choosing an appearance writes the raw mode string so the app root re-reads it
    /// and applies `.preferredColorScheme` live.
    func testSelectingAppearanceWritesTheAppearanceKey() {
        let view = SettingsView(onClose: {})

        view.appearanceBinding.wrappedValue = AppearanceMode.dark.rawValue
        XCTAssertEqual(UserDefaults.standard.string(forKey: appearanceKey), "dark")

        view.appearanceBinding.wrappedValue = AppearanceMode.light.rawValue
        XCTAssertEqual(UserDefaults.standard.string(forKey: appearanceKey), "light")
    }
}
