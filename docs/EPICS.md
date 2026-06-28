# Ball Sort Game — Epics (zero → production)

High-level breakdown. Each epic is a coherent, shippable-in-isolation slice. Ordering reflects dependencies; the **critical path** is E1 → E2 → E3 → E4 → E5. E11 (enrollment) runs in **parallel from day one** because it's external and slow.

---

## E0 — Foundations & architecture spine
Lock the engineering decisions before code. ADRs for: MVVM boundaries (logic core ↔ ViewModel ↔ View), persistence tech (SwiftData vs UserDefaults vs Codable-to-disk), view-test tooling (ViewInspector vs snapshot testing), and module layout. Output: a short `TECHNICAL_DECISIONS.md`.
**Depends on:** nothing. **Deliverable:** decisions doc.

## E1 — Project scaffold + TDD harness + CI
Xcode universal (iPhone+iPad) portrait-locked app. Swift Testing (or XCTest) wired, view-test tooling installed, a first red→green trace proving the test loop. Git repo, `.gitignore`, SwiftLint/format, CI (GitHub Actions running `xcodebuild test` on a simulator). MVVM skeleton folders.
**Depends on:** E0. **Deliverable:** empty app that builds, runs on simulator, CI green.

## E2 — Domain core: model + classic move rules _(pure Swift, full TDD)_
The heart, no UI. Immutable game-state model (tubes, balls, capacity, color count). Legal-move validation under the **classic** rule (empty tube or same-color top, destination not full). Apply-move, win detection, equality/hashing for search. This is the most testable epic — exhaustive unit tests.
**Depends on:** E1. **Deliverable:** `GameState` + rules, 100% covered.

## E3 — Level generator + solver _(the hard algorithmic epic)_
Generator that **guarantees solvability** (reverse-move scrambling and/or BFS/A* verification) and grades difficulty (tube count, colors, min-moves) to feed a rising curve. Solver doubles as the hints engine (E6). Full TDD: every generated level must pass a solver check in tests.
**Depends on:** E2. **Deliverable:** `generate(difficulty) -> solvable GameState` + `solve(state) -> moves?`.

## E4 — Game board UI (wooden-tray look, adaptive portrait)
SwiftUI port of the HTML aesthetic: warm wooden tray, glossy gradient balls, gravity-stacked tubes. Adaptive sizing iPhone↔iPad, portrait-locked. Tap-to-lift / tap-to-drop interaction, lifted + drop animations. Driven by a `BoardViewModel` (tested); view verified via snapshots.
**Depends on:** E2 (renders model). **Deliverable:** interactive board on device.

## E5 — Core gameplay loop
Wire it into a game: select/move/win flow, **undo** (move history) + **restart**, HUD (moves, time, sorted count), win overlay, "next level" advancing through the generator's curve.
**Depends on:** E3, E4. **Deliverable:** a full playable single-level→next loop.

## E6 — Hints
Solver-powered "show me a good move," surfaced in the UI (highlight source/dest). Reuses E3's solver. Designed as a clean seam so it can later become a rewarded-ad sink.
**Depends on:** E3, E5. **Deliverable:** working hint button.

## E7 — Progression, persistence & stats
Local persistence: resume an in-progress level and keep stats across relaunch. Difficulty progression state. Stats + streaks (levels solved, best moves/time, daily streak).
**Depends on:** E5. **Deliverable:** state survives relaunch; stats screen.

## E8 — Juice: sound + haptics
Drop/click/win SFX, Taptic feedback on lift/drop/complete, polish on animations and transitions. High polish-per-effort on native.
**Depends on:** E5. **Deliverable:** the game *feels* good.

## E9 — App identity & store-readiness
App icon, launch screen, settings screen (sound/haptics toggles), accessibility pass (VoiceOver, Dynamic Type, color-blind-safe ball cues), localization scaffold even if English-only.
**Depends on:** E4–E8. **Deliverable:** looks like a real app.

## E10 — Game Center _(gated on E11 enrollment)_
Leaderboards (best moves/time, levels solved) + achievements via Apple's native service — no backend. Isolated so the playable core never waits on it.
**Depends on:** E7, **E11 enrollment complete**. **Deliverable:** Game Center live.

## E11 — Release engineering _(parallel external track — START NOW)_
Apple Developer enrollment (**Tom's task**, payment + Apple ID), signing/provisioning, App Store Connect setup, privacy nutrition label (trivial — no SDKs/data collection in v1), screenshots + metadata, TestFlight beta, submission & review.
**Depends on:** enrollment (external); final build needs E9. **Deliverable:** app on the App Store.

## E12 — "Zen Garden" visual reskin _(largely shipped)_
Reskin the app to the locked Zen Garden identity (river-stones in frosted glass on a raked-sand bed, light-hero) — resolves the m7 differentiation risk (see m15). **Visual only:** Core, generator/solver, ViewModels, and classic rules are unchanged; only the App-layer `BallColor`→`Color` mapping and SwiftUI Views change. Foundation (`ZenTheme` tokens, typography, re-tuned 6-stone palette + colorblind textures, motion) + the per-component reskins (ball, tube, raked-sand tray, badge, HUD, buttons, overlay, stats, settings, launch) shipped to `main`; snapshot baselines reconciled (E12.18). The board layout was also reworked to fill the screen as a **single row** (memory m16). **Deferred:** E12.14 app icon (Tom's call), E12.16 light/dark verification pass, E12.17 iPad layouts (now single-row board + iPad form-sheets). Spec: `docs/design/ZEN_GARDEN.md` + exact tokens in `docs/design/ZEN_TOKENS.md`.
**Depends on:** E4–E9 + m15. **Deliverable:** premium, on-identity look.

## E13 — Level history, replay & appearance toggle _(shipped)_
Tom-requested post-E12 features (2026-06-27). (1) **Per-level run history** — every win is recorded as a `LevelRun` (level, moves, time, date) embedding the level's *starting board snapshot*; surfaced in a Summary/History tab on the stats sheet. (2) **Retry a specific level** — replays that exact saved board as a *side excursion*: the current level is stashed and its saved snapshot left untouched (relaunch resumes the real level), and a replay win sharpens records but doesn't advance the curve or inflate solved-count/streak (memory m19). (3) **Appearance toggle** — System/Light/Dark via `@AppStorage` + app-wide `.preferredColorScheme`; Zen tokens already carried light/dark, so this also advances E12.16. Board snapshots are stored rather than seeds because production levels use the system RNG and aren't reproducible by number.
**Depends on:** E5, E7, E12. **Deliverable:** history + replay + dark-mode preference.

## E14 — Gameplay depth: feel + guidance _(in progress — E14.1–E14.3 shipped)_
Tom-requested 2026-06-27. Deepen the core loop **without a twist mechanic** — direction chosen over a differentiating hook, scope-expansion accepted (launch may slip to get gameplay right). Two tracks. **Feel/juice** (extends E8): (A1) replace the straight-spring move with a **pour-arc** from source mouth to destination — the signature ball-sort feel; (A2) **drag-to-pour** gesture alongside taps; (A3) **win-moment particle payoff** behind the win card; (A4) **tube-completion settle** (lock/overshoot/ripple on the final ball). **Difficulty/guidance** (extends E3/E6): (B1) **fix the curve plateau** — `DifficultyCurve` flatlines by ~level 9 (colors capped 5, empty tubes floored 1, capacity fixed 4, min-moves capped 24), contradicting the brief's "infinite rising difficulty"; grow capacity and ceilings while keeping every level solver-verified; (B2) **first-run interactive tutorial** — none exists, players land cold on L1; (B3) **smarter hints** — animated nudge + a hint sound/haptic (the hint event is silent today); (B4) **difficulty label** on the level intro from the grade `DifficultyGrader` already computes. Pure-rule mechanics are unchanged, so `GAME_RULES.md` out-of-scope list is untouched.
**Shipped:** E14.1 = B1 (capacity grows 4→6, gated behind the 1-empty-tube band; min-moves ceiling 24→48; curve rises through ~L20 to genuine expert — memory m21). E14.2 = B2 (skippable/replayable 3-step tutorial; `@AppStorage("hasSeenTutorial")` gate; "How to Play" in Settings). E14.3 = A1 (flying-ball pour-arc: pure unit-tested `PourGeometry`, `PourArcEffect` GeometryEffect for the true parabola, `BoardViewModel.lastMove` seam, landed ball suppressed in-flight; verified on Tom's device). **Remaining:** A2 drag-to-pour, A3 win particles, A4 completion settle, B3 smarter hints, B4 difficulty label.
**Depends on:** E3, E6, E8, E12. **Deliverable:** a core loop that rises forever, teaches itself, and feels great to play.

---

### Critical path
`E0 → E1 → E2 → E3 → E4 → E5` gets a playable, infinitely-replayable game. E6–E9 make it shippable. E10–E11 get it live (enrollment is the long pole — overlap it from the start).

### Revisit before submission
The **differentiation** question — **RESOLVED** (m15/E12): v1's hook is the "Zen Garden" visual identity (shipped). No twist-mechanic or daily-puzzle hook for v1; revisit those post-launch if needed.
