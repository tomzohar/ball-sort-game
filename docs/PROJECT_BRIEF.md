# Ball Sort Game — Project Brief

_Shared understanding established 2026-06-25. Source of truth for scope. When this and code disagree, raise the conflict — don't silently reconcile._

## What it is

A native iOS **ball-sort puzzle** game, built up from the prototype at `~/Downloads/ballsortgame.html`. The player sorts colored balls so each tube ends up holding a single color. Target: a polished, shippable App Store product.

## Locked decisions

| Decision | Choice | Implication |
| --- | --- | --- |
| **Ambition** | Ship to App Store | ~80% of work is the meta-game (progression, persistence, polish, release), not the board. |
| **Platform** | Native **SwiftUI** | Smallest dependency surface, native haptics/feel. No cross-platform. |
| **Build/review** | Claude builds, Tom reviews | Implementation falls to Claude across sessions; Tom steers. |
| **Move rule** | **Classic** — a ball may drop only onto an empty tube or onto a same-color ball | NOT the lenient rule in the HTML prototype. Requires a solvability-guaranteeing generator. |
| **Content** | **Infinite generated** levels on a rising difficulty curve | Needs a generator + solver. No hand-authored level packs in v1. |
| **Monetization** | **Free, no ads, no SDKs** for v1 | Cleanest, fastest to store. Monetize post-launch. |
| **Devices** | iPhone **+ iPad**, **portrait only** | Universal app, portrait-locked. Adaptive layout, one orientation. |
| **Art direction** | Port the HTML **wooden-tray + glossy-ball** look faithfully | Known-good aesthetic; fastest path. |
| **Rigor** | **Full TDD** (see caveat below) | MVVM with fully-tested ViewModels + pure logic core; snapshot/ViewInspector for views. |
| **Apple Developer acct** | **Not enrolled yet** | Long-pole external blocker. Tom to start enrollment (~$99/yr, payment + Apple ID). |

## In v1

- Classic ball-sort board, tap-to-lift / tap-to-drop, drop animation.
- Infinite generated, guaranteed-solvable levels.
- Undo, restart, **solver-powered hints**.
- Sound + haptics.
- Game Center leaderboards/achievements (gated on enrollment; architected to add late).
- Stats + streaks (levels solved, best moves/time, daily streak).
- Persistence: resume in-progress level + stats survive relaunch.
- Per-level run history + retry a past level as a non-progressing side excursion (E13, added 2026-06-27 at Tom's request).
- Appearance preference: System / Light / Dark (E13).

## Deferred (post-v1)

- Themes / skins (and skins-as-IAP).
- Daily shared puzzle.
- Monetization (ads + remove-ads IAP, or paid).
- A differentiating twist mechanic — **revisit before launch**: the genre is saturated; a faithful clone risks invisibility. Flagged, not scoped.

## Raised conflicts / risks

1. **"Full TDD everywhere" vs SwiftUI.** No `renderToStaticMarkup` equivalent. Real plan: pure logic core + MVVM ViewModels carry the testable weight; views verified via snapshot tests / ViewInspector, which are weaker than web SSR assertions. View-test tooling choice is an early ADR.
2. **Apple Developer enrollment is the critical external dependency.** Start now; it gates Game Center, TestFlight, and submission. Game Center + Release are intentionally late/isolated epics so the playable core is never blocked.
3. **Genre saturation.** Differentiation deferred but must be revisited before submission.
