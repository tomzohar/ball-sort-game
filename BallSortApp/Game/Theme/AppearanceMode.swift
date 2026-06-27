import SwiftUI

/// The user's appearance preference (Settings → Appearance).
///
/// Persisted as a raw `String` under `@AppStorage(AppearanceMode.storageKey)`. The
/// default is `.system`, which follows the device's light/dark setting — the
/// composition root reads it and applies `.preferredColorScheme(colorScheme)` to the
/// root view, so the choice flows app-wide (including sheets) with no restart.
///
/// The Zen color tokens already carry light + dark values (see `ZenTheme`), so
/// forcing a scheme here is all that's needed — no per-view branching.
enum AppearanceMode: String, CaseIterable, Identifiable {
    /// Follow the device's system appearance (the default).
    case system
    /// Always light.
    case light
    /// Always dark.
    case dark

    var id: String { rawValue }

    /// The persisted `@AppStorage` key. Shared by `SettingsView` (writes) and the
    /// app root (reads + applies `.preferredColorScheme`).
    static let storageKey = "appearanceMode"

    /// Resolve a stored raw value to a mode, falling back to `.system` for an
    /// absent or unrecognized value.
    init(storedValue: String) {
        self = AppearanceMode(rawValue: storedValue) ?? .system
    }

    /// Human-readable label for the picker.
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// The SwiftUI scheme to force, or `nil` for `.system` (follow the device).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
