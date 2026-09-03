# 03 — Acrylic Studio Window Shell & Design Token System

**What to build:** A modern, high-density macOS utility studio window (`880×580 pt`) implementing Raycast-inspired acrylic translucency (`NSVisualEffectView` with `.behindWindow` blending), hairline `0.5pt` borders, strict macOS system semantic colors for Dark/Light mode, and a unified compact toolbar with view router and status capsule placeholder.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] Window background incorporates `VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)` with rounded corners (`12 pt`).
- [x] Border styling uses consistent `0.5pt` strokes (`Color.primary.opacity(0.08)` or `separatorColor`).
- [x] Design tokens for typography (13 pt body, 11 pt captions, 14 pt titles) and spacing are standardized.
- [x] Standard row density is calibrated to `38–42 pt` with `16×16 pt` / `18×18 pt` monochrome SF Symbols in `.hierarchical` rendering.
- [x] Unified compact top toolbar features section switcher (Canvas / Preferences / Diagnostics) and ambient header capsule.
- [x] UI appearance switches dynamically and seamlessly between macOS Light and Dark modes without hardcoded colors or contrast regression.

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements Component Styling, Visual Tokens & Studio Shell.
- Implemented `DesignTokens.swift` with typography, spacing, row density, hairline borders, animations, and dynamic semantic colors.
- Implemented `VisualEffectView.swift` wrapping `NSVisualEffectView` with `.underWindowBackground`, `.behindWindow`, and 12pt corner radius clipping.
- Implemented `MainWindowView.swift` with 880×580 layout, unified compact top toolbar, section router (Canvas / Settings / Diagnostics), ambient status capsule placeholder, and smooth section transitions.
- Added and verified automated test suite `DesignSystemTests.swift`.
