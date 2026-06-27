import SwiftUI

/// The per-level controls: get a hint, undo the last move, and restart the level.
/// A dumb view driven by plain values and callbacks (ADR-0001) — no game logic.
///
/// Three pill buttons styled for the wooden-tray theme (TrayBackground.swift):
/// a glowing gold **Hint** (E6) that dims when no hint is available, a warm amber
/// **Undo** that dims when there's nothing to undo, and a darker **Restart** that's
/// always tappable.
struct BoardControlsView: View {
    let canHint: Bool
    let canUndo: Bool
    let onHint: () -> Void
    let onUndo: () -> Void
    let onRestart: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onHint) {
                ControlPillLabel(
                    title: "Hint",
                    systemImage: "lightbulb.fill",
                    tint: Color(hex: 0xE0A106)
                )
            }
            .buttonStyle(ControlPillButtonStyle())
            .disabled(!canHint)
            .opacity(canHint ? 1.0 : 0.4)
            .saturation(canHint ? 1.0 : 0.0)
            .accessibilityLabel("Hint")
            .accessibilityHint(canHint ? "Show a suggested move" : "No hint available")

            Button(action: onUndo) {
                ControlPillLabel(
                    title: "Undo",
                    systemImage: "arrow.uturn.backward",
                    tint: Color(hex: 0xC98A4B)
                )
            }
            .buttonStyle(ControlPillButtonStyle())
            .disabled(!canUndo)
            .opacity(canUndo ? 1.0 : 0.4)
            .saturation(canUndo ? 1.0 : 0.0)
            .accessibilityLabel("Undo")
            .accessibilityHint(canUndo ? "Undo the last move" : "Nothing to undo")

            Button(action: onRestart) {
                ControlPillLabel(
                    title: "Restart",
                    systemImage: "arrow.clockwise",
                    tint: Color(hex: 0x5E3C1C)
                )
            }
            .buttonStyle(ControlPillButtonStyle())
            .accessibilityLabel("Restart")
            .accessibilityHint("Restart this level")
        }
    }
}

/// The contents of a control pill: an SF Symbol + label over a glossy, rounded
/// amber/wood capsule that echoes the wooden-tray look.
private struct ControlPillLabel: View {
    /// `LocalizedStringKey` so the visible button title auto-localizes (E9.5).
    let title: LocalizedStringKey
    let systemImage: String
    let tint: Color

    var body: some View {
        let shape = Capsule(style: .continuous)

        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 22)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.95), tint.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // Inset top highlight, mirroring WoodenTray's inset 0 3px highlight.
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.30), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .allowsHitTesting(false)
            )
            .clipShape(shape)
            // Border: darker wood edge, matching the tray's #5e3c1c stroke.
            .overlay(
                shape.strokeBorder(Color(hex: 0x5E3C1C), lineWidth: 1.5)
                    .allowsHitTesting(false)
            )
            // Outer drop shadow, a lighter version of the tray's drop shadow.
            .shadow(color: Color.black.opacity(0.45), radius: 6, x: 0, y: 4)
    }
}

/// Press feedback: a subtle scale + dim, no platform tint.
private struct ControlPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        GameBackground()
        VStack(spacing: 32) {
            BoardControlsView(canHint: true, canUndo: true, onHint: {}, onUndo: {}, onRestart: {})
            BoardControlsView(canHint: false, canUndo: false, onHint: {}, onUndo: {}, onRestart: {})
        }
    }
}
