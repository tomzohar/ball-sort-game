# MEMORY index — Ball Sort Game

One line per memory. Full content lives in [memory.json](memory.json).

- **m1 · decision · Classic move rule** — drop only onto empty tube or same-color top; NOT the prototype's lenient rule.
- **m2 · decision · Infinite + guaranteed-solvable levels** — generator + solver; every level provably winnable. Generation method changed in E5 → see m11.
- **m3 · decision · Native SwiftUI, universal iPhone+iPad, portrait-only** — wooden-tray look; Claude builds, Tom reviews.
- **m4 · decision · v1 free, no ads, no SDKs** — monetize later.
- **m5 · risk · 'Full TDD' on SwiftUI** — weight on logic core + tested ViewModels; views via snapshot/ViewInspector (weaker than web SSR).
- **m6 · risk · Apple Developer enrollment is the long pole** — not enrolled; gates Game Center/TestFlight/submission; Tom owns it; start now.
- **m7 · risk · Genre saturated** — pick a differentiator (theme/twist/daily) before spending on store assets.
- **m8 · context · v1 feature scope** — undo/restart/hints, sound+haptics, Game Center, stats+streaks, persistence.
- **m9 · risk · CLT-only, SwiftPM broken (RESOLVED)** — was: no Swift build/test on CLT-only Mac. Fixed by installing full Xcode 26.5; `swift test` + `xcodebuild test` now green. Lesson: CLT alone can't build SwiftPM.
- **m10 · decision · E0 architecture locked** — layered MVVM (@Observable, iOS 17) over pure Core; Codable-to-disk persistence; snapshot+VM tests; XcodeGen. Full ADRs in docs/TECHNICAL_DECISIONS.md; don't re-litigate.
- **m11 · decision · Generator = random-fill + solver-verified** — reverse-move scramble made trivial ~2-move levels; replaced (PR #17) with rejection sampling to a minMoves floor; difficulty = solver min-moves; ≤5 colors; VM generates async. App-layer DifficultyCurve drives it.
- **m12 · context · Repo is public for free macOS CI** — made public 2026-06-26 after a private-repo GitHub Actions billing block halted CI; iOS CI needs macOS runners (free on public repos).
