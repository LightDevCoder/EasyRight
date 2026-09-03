# 06 — 1:1 Real-Time Native Context Menu Mockup

**What to build:** A pixel-accurate 1:1 simulation preview component of a native macOS Finder context menu that sits alongside the staging canvas, rendering active items, monochrome SF Symbols, keyboard shortcuts, and separators in real time (60fps) as the canvas changes.

**Blocked by:** 01 — Ordered Canvas Item Data Model & FinderSync Menu Builder, 05 — Active Menu Staging Canvas & Drag-and-Drop Reordering

**Status:** resolved

- [x] Mockup component precisely mimics native macOS context menu geometry (padding, rounded corners, drop shadows, highlight state).
- [x] Renders the exact current order of actions, system separators, and submenus from `AppMenuStateCoordinator`.
- [x] Icons display matching monochrome SF Symbols with `.hierarchical` rendering matching native `NSMenuItem`.
- [x] Visual appearance dynamically adapts to system Light / Dark mode themes.
- [x] Updates reactively with zero lag whenever items are reordered, inserted, or removed in the canvas.
- [x] Hover states simulate native menu selection highlight styling (`accentColor` fill with rounded highlight pill).

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements Live Native Context Menu Mockup.
