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

    var body: some View {
        ZStack {
            GameBackground()

            VStack(spacing: 24) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                VStack(spacing: 0) {
                    Toggle("Sound", isOn: $soundEnabled)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)

                    Divider()
                        .overlay(Color.white.opacity(0.12))

                    Toggle("Haptics", isOn: $hapticsEnabled)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 18)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .tint(.green)
                .background(
                    Color.black.opacity(0.25),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .padding(.horizontal, 24)

                Button(action: onClose) {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 36)
                        .background(
                            Color.black.opacity(0.25),
                            in: Capsule()
                        )
                }
            }
        }
    }
}

#Preview {
    SettingsView(onClose: {})
}
