# Zen Garden — exact design tokens (read off the live canvas)

Captured from the Claude Design canvas (`f2dfea89-cb9c-4551-b0cf-77dc498e5580`,
`Ball Sort - Zen Garden.dc.html`) via the authenticated Omelette API on 2026-06-27.
These are the **exact** values from the token sheet — implement against these, do
not guess. This is the companion to `docs/design/ZEN_GARDEN.md` (which describes the
identity); this file holds the numbers.

## Ball palette — 6 stones (Core `BallColor` case → stone, hex, texture)

| Core case | Stone | Hex | Texture cue |
|---|---|---|---|
| `.yellow` | Amber | `#DDA63A` | rings |
| `.orange` | Persimmon | `#D27845` | dots |
| `.pink` | Plum | `#CC6B86` | diagonal |
| `.green` | Moss | `#6E9E62` | vertical |
| `.blue` | Pond | `#4E8CA8` | wave |
| `.purple` | Iris | `#8A77B8` | grid |

Each stone carries its texture as the **colorblind cue** (replaces/augments the
SF-Symbol badge): rings / dots / diagonal / vertical / wave / grid — six distinct
patterns so hue is never the only differentiator.

## Semantic color tokens (light + dark → Color asset catalog)

| Token | Light | Dark | Role |
|---|---|---|---|
| Stage | `#F4EDDE` | `#1B211A` | app background |
| Sand bed | `#E6D9BF` | `#2C3128` | surface (tray bed) |
| Stone frame | `#C9BBA0` | `#3A3F33` | frames / borders |
| Elevated | `#FBF7EF` | `#242A22` | cards / overlays |
| Text 1° | `#3B362C` | `#ECE6D6` | primary text |
| Text 2° | `#8A8170` | `#9C9686` | secondary text |
| Accent · water | `#4F9D8B` | `#6FB9A6` | accent / primary action |
| Success · moss | `#6E9E62` | `#7FB073` | success / complete |

**Light is the hero** appearance.

## Typography

- **Body / UI:** Nunito (web) → **SF Rounded** on-device.
- **Brand:** Spectral (wordmark / display moments).
- Type scale (Dynamic Type):
  - BRAND — Spectral Light · 32 (wordmark "Ball Sort")
  - DISPLAY — Nunito ExtraBold · 30/36 ("Solved!")
  - TITLE — Nunito Bold · 22/28 ("Level 7 · Hard")
  - BODY — Nunito SemiBold · 17/24
  - CAPTION — Nunito Bold · 13 · +0.08em tracking (HUD labels: MOVES/TIME/SORTED)
  - NUMERIC — Nunito ExtraBold · tabular figures (HUD values: 128, 02:14)

## Spacing / radius / elevation

- **Spacing scale:** 4 · 8 · 12 · 16 · 24 · 32
- **Corner radius:** 10 · 16 · 22 · 28 · full
- **Elevation:** rest · card · modal

## Motion language — "calm, weighted, water-like; gentle settles, never bouncy or frantic"

| Event | Behaviour | Spring / timing |
|---|---|---|
| Lift | Ball eases up ~10pt over the mouth | spring response .22, damp .80, ~180ms |
| Drop | Falls, settles with one soft rebound | spring response .30, damp .72, ~300ms |
| Illegal move | Tube shivers ±3pt, quick and quiet | shake 3 cycles ~180ms, no bounce-back |
| Tube complete | Sand ripple radiates; tube glows once | ripple scale .4→1.8, glow pulse ~600ms |
| Win | Ripples cross the bed; card fades up, stats stagger in | cascade stagger 80ms, damp .70 |
| Generating | A single rake line sweeps the empty bed | loop ease-in-out ~1.6s |

## Component states (from the canvas, section 03)

- **Ball:** idle · lifted · selected · valid-target glow. Polished river-stone,
  gloss + texture.
- **Tube:** frosted-glass cylinder in sand, capacity 4, gravity-stacked, empty
  "dimple" slots; states idle/selected/target/complete/empty.
- **Tray:** raked-sand garden bed (replaces wooden tray / dark backdrop).

> Note: the token sheet does not assign explicit per-band hex for the 5 difficulty
> bands (Trivial/Easy/Medium/Hard/Expert) — derive those in the badge unit from the
> palette (e.g. Success·moss → low difficulty … Persimmon/Plum → high), staying within
> the Zen tones above.
