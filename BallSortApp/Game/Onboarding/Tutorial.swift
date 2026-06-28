import SwiftUI

/// A single screen of the first-run tutorial: a symbol, a heading, and one short
/// instructional line. Pure value type — no behaviour, so it's trivially testable
/// and snapshot-friendly.
struct TutorialStep: Identifiable, Equatable {
    let id: Int
    /// SF Symbol shown above the heading (decorative; the copy carries the meaning).
    let symbol: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}

/// First-run onboarding namespace: the persistence key for "has the player seen the
/// tutorial" and the canonical step list teaching the classic move rule (E14.2).
enum Tutorial {
    /// `@AppStorage` key gating the first-run tutorial. Absent/`false` ⇒ show it;
    /// set `true` when finished/skipped; reset to `false` to replay from Settings.
    static let hasSeenKey = "hasSeenTutorial"

    /// The default three-beat walkthrough: the goal, the one move rule that defines
    /// the genre, and the safety net. Kept deliberately short — ball-sort is grasped
    /// in seconds and a long tutorial is worse than none. Copy mirrors
    /// `docs/GAME_RULES.md` (classic rule: top ball only, onto empty or same colour).
    static let steps: [TutorialStep] = [
        TutorialStep(
            id: 0,
            symbol: "square.stack.3d.up.fill",
            title: "Sort the Colors",
            message: "Move the balls until every tube holds a single color."
        ),
        TutorialStep(
            id: 1,
            symbol: "hand.tap.fill",
            title: "Make a Move",
            message: "Tap a tube to lift its top ball, then tap another to drop it on an empty tube or matching color."
        ),
        TutorialStep(
            id: 2,
            symbol: "lifepreserver.fill",
            title: "You're Covered",
            message: "Stuck? Undo a move, restart the level, or ask for a hint anytime."
        )
    ]
}
