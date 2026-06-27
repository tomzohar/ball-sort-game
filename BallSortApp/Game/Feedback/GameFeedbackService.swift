import Foundation

/// The production `GameFeedbackPlaying`: fans each `GameEvent` out to the synthesized
/// `SoundPlayer` and the `HapticsPlayer` (E8). Each player gates itself on its own
/// `UserDefaults` toggle, so this composite stays a dumb forwarder. It is the default
/// the `BoardViewModel` convenience init constructs, so the composition root needs no
/// change.
@MainActor
final class GameFeedbackService: GameFeedbackPlaying {
    private let players: [any GameFeedbackPlaying]

    /// Pass `nil` (the default) for the production sound + haptics pair; tests inject
    /// their own players. The default is built inside the initializer because the
    /// concrete players are `@MainActor` and cannot be constructed in a default
    /// argument expression.
    init(players: [any GameFeedbackPlaying]? = nil) {
        self.players = players ?? [SoundPlayer(), HapticsPlayer()]
    }

    func play(_ event: GameEvent) {
        for player in players {
            player.play(event)
        }
    }
}
