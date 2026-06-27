# AppIcon — branded PLACEHOLDER (E9.1)

`AppIcon-1024.png` is a **programmatically generated branded placeholder**, not
hand-designed artwork. It must be **replaced with real artwork before App Store
submission**.

- 1024×1024, sRGB, fully **opaque** (no alpha — App Store rejects transparent icons).
- No text (Apple Human Interface Guidelines).
- Theme: glossy colored balls (yellow #FFD21A hero, blue #2196F3, orange #FF7A18)
  on the warm wooden-tray background (#C98A4B → #8A5A2B), matching the brand
  palette in `BallSortApp/Game/BallColor+Color.swift` and `TrayBackground.swift`.

Generated with a CoreGraphics Swift script (kept out of the repo). To regenerate,
re-render a radial-gradient glossy ball composition at 1024×1024 with
`CGImageAlphaInfo.noneSkipLast` (opaque) into this directory.
