# Ball Sort Game

Native iOS (SwiftUI) ball-sort puzzle. Sort colored balls so each tube holds one color. Built up from the `ballsortgame.html` prototype toward an App Store release.

## Source of truth

| File | Role |
| --- | --- |
| [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md) | **Locked decisions** + scope + raised risks. The contract. |
| [docs/EPICS.md](docs/EPICS.md) | Narrative epic breakdown, dependencies, critical path. |
| [backlog/backlog.json](backlog/backlog.json) | **Tracked work** — epics → tasks → status. Source of truth for *status*. |
| [memory/memory.json](memory/memory.json) | Project memory — decisions, risks, references, context. |
| [memory/MEMORY.md](memory/MEMORY.md) | Human-readable memory index. |

Rule of precedence: PROJECT_BRIEF locks *decisions*, backlog.json tracks *status*, EPICS.md is the *narrative*. If they drift, fix the data, not the prose. When a doc and code disagree, raise the conflict — don't silently reconcile.

## Dashboard

A zero-dependency viewer over the JSON files lives in [dashboard/index.html](dashboard/index.html).

Browsers block `fetch()` of local files over `file://`, so serve the folder:

```bash
cd ~/projects/ball-sort-game
python3 -m http.server 8000
# then open http://localhost:8000/dashboard/
```

(Double-clicking the HTML shows a help banner instead of data — that's the `file://` restriction, not a bug.)

## How the systems are maintained

- **Backlog:** edit `backlog/backlog.json`. Each task has `status`: `todo` | `in_progress` | `blocked` | `done`. Add tasks under their epic; keep ids stable (`E3.2` etc.).
- **Memory:** append to `memory/memory.json` (`type`: `decision` | `risk` | `reference` | `context`) and add a one-line pointer to `memory/MEMORY.md`. One fact per entry; don't store what the code/git already records.
