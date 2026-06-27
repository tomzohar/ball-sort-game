# Ball Sort — "Zen Garden" visual identity (design reference)

**Status:** selected v1 visual identity. Resolves the m7 "pick a differentiator
before store assets" risk.
**Source of truth (live, pannable canvas):**
https://claude.ai/design/p/f2dfea89-cb9c-4551-b0cf-77dc498e5580?file=Ball+Sort+-+Zen+Garden.dc.html
**Authored in:** Claude Design (`.dc.html` artifact — HTML/JS mockup, not SwiftUI).
This doc is the implementation-facing capture; the canvas is the visual reference.

> Scope note: this is a **visual reskin only**. Classic ball-sort rules, the Core
> package, generator/solver, and all ViewModels are unchanged. The `BallColor`
> enum in Core stays as-is; only the **App-layer** mapping and Views change
> (ADR-0001/0004 folder boundaries hold).

---

## Identity

**Serene Zen Garden** — polished river-stones in frosted glass, set in a
raked-sand garden bed. Calm, meditative, premium-casual. **Light is the hero**
appearance (bright, approachable); dark mode is fully supported.

Chosen over two rejected explorations: *Premium Wood & Glass* (the prototype's
warm tray — "rich but heavy, crowded in the genre") and *Soft Clay / 3D Toy*
("calming but reads a touch childish; less premium").

## Color — 6-stone ball palette (re-tuned)

The original RGB palette was re-tuned to muted river-stone tones. Each stone
carries a **built-in colorblind-safe texture** (dots / stripes / rings) so hue is
never the only differentiator — this replaces/augments today's SF-Symbol cue
approach in `BallColor+Accessibility.swift`.

| Core `BallColor` case | Zen stone name | Texture cue |
|---|---|---|
| yellow | Amber | (per canvas) |
| orange | Persimmon | (per canvas) |
| pink | Plum | (per canvas) |
| green | Moss | (per canvas) |
| blue | Pond | (per canvas) |
| purple | Iris | (per canvas) |

> Exact hex values + texture-per-stone live on the canvas token sheet — read them
> off the live project when implementing E12.2 / E12.3 (don't guess).

Plus **semantic tokens** (light + dark): background / surface / elevated, text
primary / secondary, accent, success.

## Typography

- **Body / UI:** Nunito (web) → **SF Rounded** (on-device iOS equivalent).
- **Brand accent:** Spectral (for the wordmark / display moments).
- Full Dynamic Type scale: display / title / body / caption / numeric-HUD.

## Scales & motion

- Spacing, corner-radius, and elevation/shadow scales (token sheet).
- **Motion language:** lift; drop (bouncy settle); illegal-move shake;
  tube-complete flourish; win celebration. Maps onto `AnimationConstants.swift`.

## Components (reusable on the canvas as `ZenBall` / `ZenTube` / `AppIcon`)

- **Ball** — frosted river-stone, gloss + texture. States: idle / lifted / target.
- **Tube** — frosted-glass cylinder in sand, capacity 4, gravity-stacked, empty
  "dimple" slots. States: idle / selected / target / complete / empty.
- **Tray** — raked-sand garden bed (replaces the wooden tray / dark backdrop).
- **Difficulty badge** — level number + 5 bands (Trivial/Easy/Medium/Hard/Expert).
- **HUD pills** — Moves, Timer, Sorted progress.
- **Buttons** — primary + secondary; icon buttons: Hint, Undo, Restart, Settings, Stats.
- **Overlay card** — shared by Win and Loading overlays.

## Screens delivered on the canvas

- **iPhone:** game (mid-game) · game (mid-move: ball lifted, valid targets
  glowing) · win · loading/generating · stats · settings · launch.
- **iPad:** game (8 tubes → two balanced rows) · dark-mode win.
- **App icon:** zen-stone **cairn**, shown 1024px down to 40px and on the home screen.

Layout rules unchanged: portrait-only, universal; ≤5 tubes one row else two
balanced rows; touch targets ≥ 44pt.

## Not yet on the canvas (noted by the designer as follow-ups)

- iPad Stats / Settings as centered form-sheets (only shown on iPhone).
- A full dark-mode **game** screen (dark was demonstrated via the iPad win only).

## Mapping to existing code (for the E12 implementation epic)

| Design piece | Existing file(s) to rework |
|---|---|
| Semantic tokens, spacing/radius/elevation | new `ZenTheme`/tokens in App layer + Color assets |
| 6-stone palette | `BallColor+Color.swift` (App mapping only) |
| Textured colorblind cue | `BallView.swift`, `BallColor+Accessibility.swift` |
| Typography | new font registration + text styles |
| ZenBall | `BallView.swift` |
| ZenTube | `TubeView.swift` |
| Raked-sand tray/background | `TrayBackground.swift` (was WoodenTray/GameBackground) |
| Difficulty badge (+ level wrap fix) | `DifficultyBadgeView.swift` |
| HUD pills | `GameHUDView.swift` |
| Buttons / icon buttons | `BoardControlsView.swift`, `RootView.swift` top bar |
| Overlay card / Win / Loading | `WinOverlayView.swift`, generating overlay in `RootView.swift` |
| Stats screen | `StatsScreen.swift` / `StatsView.swift` |
| Settings screen | `SettingsView.swift` |
| Launch screen | launch storyboard/assets |
| App icon (cairn) | `Assets.xcassets/AppIcon.appiconset` (replaces E9 placeholder) |
| Motion | `AnimationConstants.swift` |
