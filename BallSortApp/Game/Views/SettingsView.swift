import SwiftUI

/// The settings sheet: two toggles (sound, haptics) over the dark game backdrop,
/// with a Done button to dismiss. Both toggles bind directly to `@AppStorage`, so
/// flipping one writes the matching `UserDefaults` key the feedback players read at
/// play-time — the change applies live, no restart. This view owns no logic beyond
/// the two bindings; it stays dumb (E9.3).
///
/// The keys and `true` defaults mirror the players' `?? true` fallback
/// (`SoundPlayer` / `HapticsPlayer`) so the stored values stay consistent.
struct SettingsView: View {
    /// Whether sound effects play. Backs `SoundPlayer`'s gate.
    @AppStorage("soundEnabled") private var soundEnabled = true
    /// Whether haptic feedback fires. Backs `HapticsPlayer`'s gate.
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true

    /// Invoked when the player taps Done.
    let onClose: () -> Void

    /// Test-facing handle on the sound binding. The `@AppStorage` projected value is
    /// `private`; exposing it lets `SettingsViewTests` drive the same write path the
    /// `Toggle` uses, without an OS-fragile snapshot.
    var soundEnabledBinding: Binding<Bool> { $soundEnabled }
    /// Test-facing handle on the haptics binding (see `soundEnabledBinding`).
    var hapticsEnabledBinding: Binding<Bool> { $hapticsEnabled }

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
                .zenShadow(.soft)
                .padding(.horizontal, ZenSpacing.lg)

                Button(action: onClose) {
                    Text("Done")
                        .font(ZenFont.button)
                        .foregroundStyle(ZenColor.textPrimary)
                        .padding(.vertical, ZenSpacing.sm + ZenSpacing.xs)
                        .padding(.horizontal, ZenSpacing.xl + ZenSpacing.xs)
                        .background(ZenColor.elevated, in: Capsule())
                        .overlay(Capsule().strokeBorder(ZenColor.stoneFrame, lineWidth: 1))
                        .zenShadow(.soft)
                }
            }
        }
    }
}

#Preview {
    SettingsView(onClose: {})
}
