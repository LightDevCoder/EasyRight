# 04 — Action Library Pane & Reactive State Coordinator

**What to build:** A centralized reactive state coordinator (`AppMenuStateCoordinator`) managing the active menu sequence and library catalog, paired with a searchable Action Library left pane featuring category chips (New File, File Manage, Terminal/IDE, Utilities), instant enable toggles, and drag sources.

**Blocked by:** 01 — Ordered Canvas Item Data Model & FinderSync Menu Builder, 03 — Acrylic Studio Window Shell & Design Token System

**Status:** resolved

- [x] `AppMenuStateCoordinator` manages library actions, staging items, selection state, and debounced persistence to `SharedStorageManager`.
- [x] Action Library displays all available built-in actions with clean rows, icon, title, and category metadata.
- [x] Category filter chips (All, New File, File Manage, Terminal/IDE, Utilities) allow quick switching.
- [x] Instant search field filters actions in real time with keyboard shortcut support.
- [x] Direct `+` / toggle button enables/disables actions, instantly reflecting their staged presence in the active menu.
- [x] Library items provide draggable payloads for drag-and-drop insertion into the canvas.

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements Seam B (Host Application Presentation & State Coordinator) & Action Library.
