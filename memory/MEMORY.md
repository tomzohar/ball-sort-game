# MEMORY index — Ball Sort Game

One line per memory. Full content lives in [memory.json](memory.json).

- **m1 · decision · Classic move rule** — drop only onto empty tube or same-color top; NOT the prototype's lenient rule.
- **m2 · decision · Infinite + guaranteed-solvable levels** — generator + solver; every level provably winnable. Generation method changed in E5 → see m11.
- **m3 · decision · Native SwiftUI, universal iPhone+iPad, portrait-only** — wooden-tray look; Claude builds, Tom reviews.
- **m4 · decision · v1 free, no ads, no SDKs** — monetize later.
- **m5 · risk · 'Full TDD' on SwiftUI** — weight on logic core + tested ViewModels; views via snapshot/ViewInspector (weaker than web SSR).
- **m6 · risk · Apple Developer enrollment is the long pole** — not enrolled; gates Game Center/TestFlight/submission; Tom owns it; start now.
- **m7 · risk · Genre saturated (RESOLVED by m15)** — was: pick a differentiator before store assets. Resolved via the Zen Garden visual identity (m15 / E12).
- **m8 · context · v1 feature scope** — undo/restart/hints, sound+haptics, Game Center, stats+streaks, persistence.
- **m9 · risk · CLT-only, SwiftPM broken (RESOLVED)** — was: no Swift build/test on CLT-only Mac. Fixed by installing full Xcode 26.5; `swift test` + `xcodebuild test` now green. Lesson: CLT alone can't build SwiftPM.
- **m10 · decision · E0 architecture locked** — layered MVVM (@Observable, iOS 17) over pure Core; Codable-to-disk persistence; snapshot+VM tests; XcodeGen. Full ADRs in docs/TECHNICAL_DECISIONS.md; don't re-litigate.
- **m11 · decision · Generator = random-fill + solver-verified** — reverse-move scramble made trivial ~2-move levels; replaced (PR #17) with rejection sampling to a minMoves floor; difficulty = solver min-moves; ≤5 colors; VM generates async. App-layer DifficultyCurve drives it.
- **m12 · context · Repo is public for free macOS CI** — made public 2026-06-26 after a private-repo GitHub Actions billing block halted CI; iOS CI needs macOS runners (free on public repos).
- **m13 · decision · E6 hint = solver.solve().first, off-main** — `requestHint()` reuses E3's Solver off the main actor, stores `hintMove`, highlights source (solid gold) + dest (dashed gold); cleared on any board mutation. It's the rewarded-ad seam.
- **m15 · decision · v1 identity = Zen Garden (resolves m7)** — Serene Zen Garden skin (river-stones in frosted glass on raked sand, light-hero); re-tuned 6-stone palette + textured colorblind cues; zen-cairn icon. From Claude Design (preferred over Stitch); spec in docs/design/ZEN_GARDEN.md; implemented as epic E12 (visual reskin only).
- **m14 · decision · E7 persistence seam** — generic `PersistenceStore` + `JSONFileStore` (App Support JSON) + in-memory fake; `SavedGame` envelope persisted by `BoardViewModel.persistProgress()` and restored via `BoardViewModel(restoring:)`; `StatsStore` (@Observable) owns `GameStats`, recorded on win (yyyymmdd streak key). Composition root in `BallSortApp.init()`. Stats sheet from RootView top-bar button.
- **m16 · decision · Board = single-row, screen-filling (overrides E12 two-row spec)** — all tubes in one HStack; `BoardLayout.fittedBallSize` fits both width+height, `filledBallGap` spreads the column (cap 0.45×ball); trimmed tube overhead for bigger balls. Don't restore two rows.
- **m17 · context · E12 Zen Garden shipped to main** — foundation + 10 reskins + snapshot reconcile on main; tokens in docs/design/ZEN_TOKENS.md. Spectral brand font STUBBED with system serif (TODO); E12.14/16/17 deferred.
- **m18 · risk · iOS dev-env gotchas** — don't fan out many local xcodebuilds (melts the Mac); `rm -rf BallSort.xcodeproj && xcodegen generate` if app scheme missing; re-record snapshots via `TEST_RUNNER_SNAPSHOT_TESTING_RECORD=all` (but `.missing`-pinned tests need flipping to `.all`).
- **m20 · decision · E14 = gameplay depth (feel + guidance), not a twist** — Tom chose richer game-feel + difficulty/guidance over a differentiating mechanic; scope expansion accepted (launch may slip). Key finding: `DifficultyCurve` PLATEAUS by ~level 9, contradicting the brief's "infinite rising difficulty" (B1 = fix it, recommended first). No first-run tutorial; move anim is a straight spring not a pour-arc; hint event is silent. Differentiation stays the Zen skin (m15).
