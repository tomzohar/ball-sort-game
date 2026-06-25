# CLAUDE.md

Operational rules for AI coding agents working in this repo. Keep it loaded every session. When this file and a pillar doc disagree, the pillar doc wins — raise the conflict, don't silently reconcile.

## Project

Native iOS (SwiftUI) **ball-sort puzzle** game, built up from the `ballsortgame.html` prototype toward an **App Store release**. The player sorts colored balls so each tube holds a single color. Built solo: **Claude implements, Tom reviews.** v1 is free, no ads, no SDKs. See `docs/PROJECT_BRIEF.md` for the full locked scope.

## Pillar docs (read first, source of truth)

- `docs/PROJECT_BRIEF.md` — locked decisions, scope (in/out), raised risks. The contract.
- `docs/EPICS.md` — E0–E11 narrative, dependencies, critical path.
- `docs/GAME_RULES.md` — the game mechanic spec (move rule, win condition, generation, difficulty).
- `docs/TECHNICAL_DECISIONS.md` — binding engineering ADRs (architecture, persistence, testing, project layout).
- `backlog/backlog.json` — tracked work, source of truth for **status**. `dashboard/index.html` renders it.
- `memory/memory.json` (+ `MEMORY.md` index) — durable project knowledge across sessions.

Precedence: PROJECT_BRIEF locks *decisions*, backlog.json tracks *status*, EPICS is the *narrative*. Fix the data, not the prose, when they drift.

## Stack invariants

One line each; rationale in `docs/TECHNICAL_DECISIONS.md`.

- **Language / UI:** Swift, SwiftUI. Min deployment **iOS 17.0** (ADR-0001, `@Observable`).
- **Architecture:** layered MVVM — `Views → ViewModels (@Observable) → BallSortCore`. Core depends on nothing UI (ADR-0001).
- **Logic core:** `BallSortCore/` Swift package — pure value types, rules, solver, generator. No SwiftUI/UIKit. Tested via `swift test`, no simulator.
- **App target:** defined as code in `project.yml` via **XcodeGen** (ADR-0004). The generated `BallSort.xcodeproj` is **gitignored** — `project.yml` is the source of truth.
- **Persistence:** `Codable`-to-disk (JSON in Application Support) behind a `PersistenceStore` protocol; `@AppStorage` for settings toggles. **No SwiftData** (ADR-0002).
- **DI:** ViewModels take Core capabilities through protocols (`LevelGenerating`, `Solving`, `PersistenceStore`); fakes injected in tests.
- **View tests:** pointfree `swift-snapshot-testing` for the ball/tube/board primitives (ADR-0003).
- **Lint:** SwiftLint (`.swiftlint.yml`), `lint --strict` must be clean.

Forbidden without an ADR amendment: SwiftData, third-party auth/analytics/ad SDKs (v1 is SDK-free), `ObservableObject` for new ViewModels (use `@Observable`), hardcoding the BallColor palette outside the App-layer mapping.

## Game rules

The mechanic is specified in `docs/GAME_RULES.md` — that doc is authoritative. The one rule worth repeating because it's the most likely to be silently broken: this is **classic ball-sort** (move onto an empty tube or a same-color, non-full top — top ball only), **not** the prototype's lenient any-ball-any-space rule (memory m1). Don't reintroduce the lenient rule.

## Development approach: TDD

**Tests land before implementation.** The RED → GREEN trace is the standard rhythm; narrate it in commit messages.

- **Core (model/rules/solver/generator):** full behaviour TDD with Swift Testing. Exhaustive — this is where puzzle bugs hide and it's trivially testable.
- **ViewModels:** unit-test every intent → state transition (select, move, undo, restart, hint, win, next level). No SwiftUI import needed.
- **Views:** kept dumb. Targeted snapshot tests for the visual primitives only. Plus: **any PR touching UI includes a real screenshot** (running app, portrait) — class/structure assertions don't catch visual breakage (ADR-0003, memory m5).

If a task doesn't fit TDD, say so in the PR and explain the alternative verification — don't silently skip.

## Folder boundaries

- `BallSortApp/` (Views + ViewModels) depends on `BallSortCore`; **never the reverse**.
- `BallSortCore/` imports **no** SwiftUI/UIKit. Keep it pure and `Sendable`.
- BallColor → SwiftUI Color mapping lives in the **App layer** (`BallSortApp/Game/BallColor+Color.swift`), never in Core.
- Composition root (concrete generator/solver/store construction) lives at the app entry, injected downward.

## Build & test

Requires full Xcode (not Command Line Tools — memory m9) + XcodeGen (`brew install xcodegen`).

```bash
cd BallSortCore && swift test                 # logic core, fast, no simulator
xcodegen generate                             # after any project.yml change
xcodebuild test -project BallSort.xcodeproj -scheme BallSortApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
swiftlint lint --strict                        # must be clean
```

CI (`.github/workflows/ci.yml`) runs all of the above on every push/PR. Keep it green.

## Conventions

- **Conventional Commits**, lowercase subject. End commit messages with `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`.
- Work epics on a branch as a PR (`feat/e2-domain-core`, …) so CI gates before merge.
- Don't commit the generated `.xcodeproj`, `.build/`, or `DerivedData/` (already gitignored).
- **Backlog:** edit `backlog/backlog.json` — keep task ids stable, set `status` (`todo`/`in_progress`/`blocked`/`done`).
- **Memory:** append to `memory/memory.json` (`decision`/`risk`/`reference`/`context`) + a line in `MEMORY.md`. One fact per entry; don't store what code/git already records.

## When in doubt

- Pillar doc vs code: pillar doc wins. Raise the conflict.
- A proposed feature conflicts with `docs/PROJECT_BRIEF.md` scope: default to "no" / defer to post-v1.
- A change contradicts a recorded ADR/memory: amend `docs/TECHNICAL_DECISIONS.md` with the new choice and rationale — don't diverge silently.
- Outward-facing or account/payment actions (App Store, Apple Developer enrollment, repo visibility): confirm with Tom first.
