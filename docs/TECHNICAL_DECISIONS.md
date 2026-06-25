# Technical Decisions — Ball Sort Game

ADR-style record of binding engineering decisions. When this doc and the code disagree, fix the code or amend this doc with rationale — don't silently diverge. Mirrors the know-the-night convention.

Each ADR: **Context → Decision → Consequences → Rejected alternatives.**

---

## ADR-0001 — Layered MVVM over a pure logic Core
_Status: Accepted · 2026-06-25 · E0.1_

### Context
We want "full TDD" (PROJECT_BRIEF, memory m5) but SwiftUI views resist cheap testing. The way out is to keep almost all logic out of the view layer, in code that tests without a simulator.

### Decision
Three layers, strict one-way dependencies (`Views → ViewModels → Core`; Core depends on nothing):

1. **Core** — the `BallSortCore` Swift package. Pure value types and algorithms: `BallColor`, `Tube`, `GameState`, `Move`, the classic move rules, the solver, the generator. **No SwiftUI, no UIKit, no Foundation-UI.** Deterministic and `Sendable`. This is where the puzzle *is*, and it's exhaustively unit-tested from the command line.
2. **ViewModels** — `@Observable` classes (Swift **Observation** framework, iOS 17+) in the app target. They own the current `GameState`, the move history (undo), selection/transient UI state, and derived presentation (moves count, elapsed time, solved flag). They translate user intent into Core calls. They import `Observation` and `BallSortCore` — **not** SwiftUI — so they unit-test like any other object.
3. **Views** — dumb SwiftUI. Render ViewModel state, fire intent callbacks. No game rules, no persistence, minimal branching.

**Dependency injection:** ViewModels receive Core capabilities through protocols — `LevelGenerating`, `Solving`, `PersistenceStore` — so tests inject fakes (mirrors the know-the-night DI-split discipline). Concrete implementations are constructed at the app composition root and passed down.

**Minimum deployment target: iOS 17.0.** Unlocks the `@Observable` macro and modern SwiftUI; by 2026 it covers essentially all active devices. (Universal app, portrait-only — PROJECT_BRIEF.)

### Consequences
- The testable surface (Core + ViewModels) is ~all of the logic and carries the TDD weight.
- Views become thin enough that their correctness is mostly visual, which ADR-0003 addresses.
- iOS 17 floor is a deliberate trade: a little reach for a lot less boilerplate.

### Rejected alternatives
- **`ObservableObject` + `@Published`** — more boilerplate, Combine churn, and would let us target iOS 16; not worth it given iOS 17's reach in 2026.
- **"MV" (no ViewModel, logic in views)** — collapses the testable layer back into SwiftUI. Exactly what we're avoiding.

---

## ADR-0002 — Persistence: Codable-to-disk + AppStorage, not SwiftData
_Status: Accepted · 2026-06-25 · E0.2_

### Context
We persist three things: (a) the in-progress level so the player can resume, (b) stats + streaks, (c) settings toggles (sound/haptics). All small, single-user, non-relational, no sync. Core types are already value types.

### Decision
- **Game state + stats:** make the relevant Core types `Codable` and persist them as **JSON files in Application Support**, behind a `PersistenceStore` protocol. The protocol is injected (ADR-0001), so tests use an in-memory fake — no disk, no framework.
- **Settings toggles:** `@AppStorage` (UserDefaults). Trivial key-values that bind directly to SwiftUI controls; not worth a file.

### Consequences
- Core stays pure and framework-free; persistence is a thin, fully-testable boundary.
- Schema "migration" is just Codable defaulting / versioning a small struct — no migration ceremony.

### Rejected alternatives
- **SwiftData** — built for relational/queryable/syncable data we don't have. Wrapping a pure value-type `GameState` in an `@Model` would either pollute Core or need a mapping layer anyway. Overkill; harder to unit-test. Reconsider only if post-v1 features (cloud sync, large history) demand it.
- **Everything in UserDefaults** — clumsy and error-prone for the nested game state.

---

## ADR-0003 — Testing: Core/VM unit tests primary; targeted snapshot tests + PR screenshots for views
_Status: Accepted · 2026-06-25 · E0.3_

### Context
Risk m5: SwiftUI has no `renderToStaticMarkup` equivalent. "Full TDD everywhere" must be defined honestly. The know-the-night lesson (the "tiny ovals" bug) is that class/structure assertions don't catch *visual* breakage — only a rendered image does.

### Decision
Three tiers:
1. **Core unit tests** (Swift Testing) — exhaustive: model invariants, the classic move rule, win detection, solver correctness, generator solvability. Test-first, the RED→GREEN rhythm.
2. **ViewModel unit tests** — every intent → state transition (select, move, undo, restart, hint, win, next level). No SwiftUI needed.
3. **Targeted snapshot tests** (pointfreeco `swift-snapshot-testing`) for the visual primitives only — `BallView` and `TubeView` in each state (empty, filled, lifted, selected, complete) and the assembled `BoardView` at one iPhone + one iPad size. Reference images pinned to a single simulator device/OS, recorded intentionally, run in CI on a matching runner.

Plus the carried-over **project rule: any PR touching UI includes a real screenshot** (the running app, RTL/portrait, per-state where relevant).

### Consequences
- Behavioral correctness is locked by fast, deterministic unit tests.
- Visual regressions are caught at the primitive level (cheapest place) without trying to snapshot every screen.
- Snapshot suite is small on purpose, to limit the simulator/Xcode-version flakiness those tests are prone to.

### Rejected alternatives
- **ViewInspector** — asserts the view tree without rendering, but it's third-party, lags SwiftUI changes, gets brittle on real hierarchies, and still wouldn't catch *visual* bugs. Snapshot + VM tests cover the same space with less ceremony.
- **No view tests at all** — leans entirely on manual screenshots; too easy to regress the ball/tube rendering silently.

---

## ADR-0004 — Project layout & generation via XcodeGen
_Status: Accepted · 2026-06-25 · E0.4_

### Context
Claude builds but cannot open Xcode (and full Xcode isn't even installed yet — m9). A binary `.pbxproj` is unreviewable and merge-hostile. We want the project definition to be **code Claude can author and Tom can regenerate.**

### Decision
Define the Xcode app target with **XcodeGen** (`project.yml`, authored as text). Tom runs `brew install xcodegen && xcodegen generate` after installing Xcode (E1.1). The app references the logic core as a **local Swift package** (`./BallSortCore`).

Repo layout (once the app target lands):

```
ball-sort-game/
├── BallSortCore/                      # SPM package — pure logic (Model layer)
│   ├── Package.swift
│   ├── Sources/BallSortCore/
│   │   ├── Model/      # BallColor, Tube, GameState, Move
│   │   ├── Rules/      # legal-move validation, win detection
│   │   ├── Solver/     # BFS/A* solver  (also powers hints)
│   │   └── Generator/  # reverse-move generator, difficulty grading
│   └── Tests/BallSortCoreTests/
├── project.yml                        # XcodeGen spec (authored as code)
├── BallSortApp/                       # generated Xcode app target (VM + View)
│   ├── App/          # entry point, composition root
│   ├── Game/         # GameViewModel, BoardView, TubeView, BallView, HUDView, WinOverlay
│   ├── Stats/        # StatsViewModel, StatsView
│   ├── Settings/     # SettingsView (+ @AppStorage)
│   ├── Persistence/  # PersistenceStore protocol + JSONFileStore
│   └── Resources/    # assets, sounds
├── BallSortAppTests/                  # ViewModel unit + snapshot tests
├── docs/ · backlog/ · memory/ · dashboard/
```

**Boundary rule:** `BallSortApp` depends on `BallSortCore`; `BallSortCore` depends on nothing UI. Enforced by the package having no SwiftUI/UIKit imports.

### Consequences
- The project is diffable, reproducible, and editable without opening Xcode.
- Adds one tool (XcodeGen) to the bootstrap.

### Rejected alternatives
- **Hand-created Xcode project** — lowest friction for one target, but unreviewable binary project file and Claude can't author it. 
- **Tuist** — more powerful than we need for a single-target game; heavier setup.
