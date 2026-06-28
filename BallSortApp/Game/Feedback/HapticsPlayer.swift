import UIKit

/// Maps `GameEvent`s to UIKit haptic feedback (E8.2). Impact generators handle the
/// physical-collision feel (lift / drop / tube-complete); the notification generator
/// handles outcome cues (illegal move / win). Generators are lazily created and
/// `prepare()`d so the first buzz isn't delayed. Playback is gated on the
/// `hapticsEnabled` setting (default on).
@MainActor
final class HapticsPlayer: GameFeedbackPlaying {
    private lazy var lightImpact = makeImpact(.light)
    private lazy var softImpact = makeImpact(.soft)
    private lazy var rigidImpact = makeImpact(.rigid)
    private lazy var heavyImpact = makeImpact(.heavy)
    private lazy var notification = makeNotification()

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    func play(_ event: GameEvent) {
        guard isEnabled else { return }
        switch event {
        case .lift:
            lightImpact.impactOccurred()
        case .drop, .undo:
            rigidImpact.impactOccurred()
        case .tubeComplete:
            heavyImpact.impactOccurred()
        case .illegalMove:
            notification.notificationOccurred(.error)
        case .win:
            notification.notificationOccurred(.success)
        case .hint:
            // A soft tap — a gentle "look here" that's lighter than a move's rigid drop.
            softImpact.impactOccurred()
        }
    }

    private func makeImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        return generator
    }

    private func makeNotification() -> UINotificationFeedbackGenerator {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }
}
