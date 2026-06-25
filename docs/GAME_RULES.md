# Game Rules — Ball Sort Game

The authoritative spec for the game mechanic. Behaviour described here wins over any code; if they disagree, fix the code or amend this doc. Builds on the locked decision in `PROJECT_BRIEF.md` (classic rule) and memories m1/m2.

## Objective

Sort the balls so that **each tube holds a single color** (or is empty). A level is **solved** when every tube is either empty or a full single-color stack.

## Board

- A level has **N colors** and **N color-filled tubes**, plus **one or more empty spare tubes** (the prototype used a single leftmost spare). Color count == number of full tubes.
- Every tube has a fixed **capacity** (balls per tube), equal to the number of balls of each color.
- Balls stack bottom-to-top with gravity; only the arrangement matters, not physics.

## The move (classic rule)

A move lifts the **top ball of a source tube** and drops it onto a destination tube. The move is **legal only if** the destination is:

- **empty**, or
- topped by a ball of the **same color** as the lifted ball,

**and** the destination is **not full**.

Clarifications:
- Only the single top ball moves (no multi-ball pours in v1 — revisit only via ADR if desired).
- A ball may not move onto a different color, even if space remains. This is the strategic constraint and the whole point of the genre.
- Lifting from an empty tube is a no-op. Dropping onto the source tube cancels the selection.

> This is the **classic** rule. The `ballsortgame.html` prototype used a *lenient* rule (any ball onto any tube with space) — **do not** reintroduce it (memory m1).

## Win condition

`solved == every tube is empty OR (full AND all balls one color)`. A tube is **complete** when full of a single color; the HUD may show completed-tube progress (`sorted / N`).

## Level generation (must be solvable)

- Levels are **infinite and generated** on a rising difficulty curve — no hand-authored packs in v1 (memory m2).
- Every generated level **must be guaranteed solvable** under the classic rule. A random shuffle is often unsolvable, so generation uses reverse-move scrambling and/or solver verification (E3).
- The solver that guarantees solvability also powers **hints** (E6).

## Difficulty

Graded by number of colors, number of tubes/spares, capacity, and minimum-moves-to-solve. The curve raises these over successive levels (E3.4). Prototype reference points: Easy 4×4, Classic 5×5, Hard 6×6 (colors × capacity).

## Player affordances (v1)

- **Undo** the last move and **restart** the level (near-mandatory for the genre).
- **Hints** — surface a solver-derived legal, progress-making move.

## Out of scope for v1

Multi-ball pours, locked/special balls, move limits, timed modes, or any twist mechanic. Differentiation hooks are deferred and tracked separately (memory m7).
