import SwiftUI

/// The settings sheet: sound + haptics toggles and an appearance picker over the
/// game backdrop, with a Done button to dismiss. Each control binds directly to
/// `@AppStorage`, so changing one writes the matching `UserDefaults` key live, no
/// restart — the feedback players read their keys at play-time and the composition
/// root re-reads the appearance key to drive `.preferredColorScheme`. This view owns
/// no logic beyond its bindings; it stays dumb (E9.3).
///
/// The toggle keys and `true` defaults mirror the players' `?? true` fallback
/// (`SoundPlayer` / `HapticsPlayer`) so the stored values stay consistent.
struct SettingsView: View {
    /// Whether sound effects play. Backs `SoundPlayer`'s gate.
    @AppStorage("soundEnabled") private var soundEnabled = true
    /// Whether haptic feedback fires. Backs `HapticsPlayer`'s gate.
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    /// The light/dark appearance preference. Backs the app root's
    /// `.preferredColorScheme`; defaults to `.system` (follow the device).
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue
    /// First-run tutorial flag (E14.2). "How to Play" clears it so `RootView` shows
    /// the walkthrough again.
    @AppStorage(Tutorial.hasSeenKey) private var hasSeenTutorial = false

    /// Invoked when the player taps Done.
    let onClose: () -> Void

    /// Test-facing handle on the sound binding. The `@AppStorage` projected value is
    /// `private`; exposing it lets `SettingsViewTests` drive the same write path the
    /// `Toggle` uses, without an OS-fragile snapshot.
    var soundEnabledBinding: Binding<Bool> { $soundEnabled }
    /// Test-facing handle on the haptics binding (see `soundEnabledBinding`).
    var hapticsEnabledBinding: Binding<Bool> { $hapticsEnabled }
    /// Test-facing handle on the appearance binding (see `soundEnabledBinding`).
    var appearanceBinding: Binding<String> { $appearanceRaw }
    /// Test-facing handle on the tutorial flag (see `soundEnabledBinding`).
    var hasSeenTutorialBinding: Binding<Bool> { $hasSeenTutorial }

    var body: some View {
        ZStack {
            // Raked-sand garden bed: light-hero stage backdrop (ZEN_GARDEN.md).
            ZenColor.stage
                .ignoresSafeArea()

            VStack(spacing: ZenSpacing.xl) {
                Text("Settings")
                    .font(ZenFont.title)
                    .foregroundStyle(ZenColor.textPrimary)

                VStack(spacing: 0) {
                    Toggle("Sound", isOn: $soundEnabled)
                        .padding(.vertical, ZenSpacing.md)
                        .padding(.horizontal, ZenSpacing.lg)

                    Divider()
                        .overlay(ZenColor.stoneFrame)

                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .padding(.vertical, ZenSpacing.md)
                        .padding(.horizontal, ZenSpacing.lg)

                    Divider()
                        .overlay(ZenColor.stoneFrame)

                    VStack(alignment: .leading, spacing: ZenSpacing.sm) {
                        Text("Appearance")
                        Picker("Appearance", selection: $appearanceRaw) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.label).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, ZenSpacing.md)
                    .padding(.horizontal, ZenSpacing.lg)

                    Divider()
                        .overlay(ZenColor.stoneFrame)

                    // Replays the first-run walkthrough: clear the flag and dismiss the
                    // sheet so RootView presents the tutorial over the board (E14.2).
                    Button {
                        hasSeenTutorial = false
                        onClose()
                    } label: {
                        HStack {
                            Text("How to Play")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(ZenFont.caption)
                                .foregroundStyle(ZenColor.textSecondary)
                        }
                        .padding(.vertical, ZenSpacing.md)
                        .padding(.horizontal, ZenSpacing.lg)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .font(ZenFont.headline)
                .foregroundStyle(ZenColor.textPrimary)
                .tint(ZenColor.accent)
                .background(
                    ZenColor.elevated,
                    in: RoundedRectangle(cornerRadius: ZenRadius.md, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ZenRadius.md, style: .continuous)
                        .strokeBorder(ZenColor.stoneFrame, lineWidth: 1)
                )
                .zenShadow(.card)
                .padding(.horizontal, ZenSpacing.lg)

                Button(action: onClose) {
                    Text("Done")
                        .font(ZenFont.button)
                        .foregroundStyle(ZenColor.textPrimary)
                        .padding(.vertical, ZenSpacing.sm + ZenSpacing.xs)
                        .padding(.horizontal, ZenSpacing.xl + ZenSpacing.xs)
                        .background(ZenColor.elevated, in: Capsule())
                        .overlay(Capsule().strokeBorder(ZenColor.stoneFrame, lineWidth: 1))
                        .zenShadow(.card)
                }
            }
        }
        // The app root applies `.preferredColorScheme` for the main window, but a
        // `.sheet` is hosted in a separate presentation context that doesn't re-read
        // that root modifier reactively — so without this, flipping the Appearance
        // picker only restyles the board behind the sheet, not the sheet itself, until
        // it's reopened. Applying it here (driven by the same key) makes the change
        // live in the sheet too (E13).
        .preferredColorScheme(AppearanceMode(storedValue: appearanceRaw).colorScheme)
    }
}

#Preview {
    SettingsView(onClose: {})
}
