import SwiftUI

/// The per-level controls: get a hint, undo the last move, and restart the level.
/// A dumb view driven by plain values and callbacks (ADR-0001) — no game logic.
///
/// Three Zen Garden pill buttons (E12.9): a calm **water-teal Hint** (E6, the
/// primary action) that dims when no hint is available, and two quieter
/// **elevated/stone-framed** secondary pills — **Undo** (dims when there's nothing
/// to undo) and an always-tappable **Restart**.
struct BoardControlsView: View {
    let canHint: Bool
    let canUndo: Bool
    let onHint: () -> Void
    let onUndo: () -> Void
    let onRestart: () -> Void

    var body: some View {
        HStack(spacing: ZenSpacing.lg) {
            Button(action: onHint) {
                ControlPillLabel(
                    title: "Hint",
                    systemImage: "lightbulb.fill",
                    style: .primary
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
                    style: .secondary
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
                    style: .secondary
                )
            }
            .buttonStyle(ControlPillButtonStyle())
            .accessibilityLabel("Restart")
            .accessibilityHint("Restart this level")
        }
    }
}

/// The contents of a control pill in the Zen Garden tokens.
///
/// `.primary` is the water-teal accent fill (primary action); `.secondary` is a
/// calm `elevated` surface with a hairline `stoneFrame` border. Both ride a full
/// (capsule) radius and a soft `rest` elevation, with a minimum 44pt touch target.
private struct ControlPillLabel: View {
    enum Style {
        case primary
        case secondary
    }

    /// `LocalizedStringKey` so the visible button title auto-localizes (E9.5).
    let title: LocalizedStringKey
    let systemImage: String
    let style: Style

    private var foreground: Color {
        switch style {
        case .primary: return .white
        case .secondary: return ZenColor.textPrimary
        }
    }

    @ViewBuilder
    private var fill: some View {
        switch style {
        case .primary: ZenColor.accent
        case .secondary: ZenColor.elevated
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return ZenColor.accent
        case .secondary: return ZenColor.stoneFrame
        }
    }

    var body: some View {
        let shape = Capsule(style: .continuous)

        Label(title, systemImage: systemImage)
            .font(ZenFont.body)
            .foregroundStyle(foreground)
            .padding(.vertical, ZenSpacing.md)
            .padding(.horizontal, ZenSpacing.xl)
            // ≥44pt touch target (canvas minimum).
            .frame(minHeight: 44)
            .background(fill)
            .clipShape(shape)
            .overlay(
                shape.strokeBorder(borderColor, lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .zenShadow(.rest)
    }
}

/// Press feedback: a calm, water-like scale + dim — no platform tint, never bouncy.
private struct ControlPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        GameBackground()
        VStack(spacing: ZenSpacing.xxl) {
            BoardControlsView(canHint: true, canUndo: true, onHint: {}, onUndo: {}, onRestart: {})
            BoardControlsView(canHint: false, canUndo: false, onHint: {}, onUndo: {}, onRestart: {})
        }
    }
}
