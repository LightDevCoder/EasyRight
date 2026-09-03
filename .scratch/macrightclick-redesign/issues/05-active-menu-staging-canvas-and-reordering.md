# 05 — Active Menu Staging Canvas & Drag-and-Drop Reordering

**What to build:** An interactive Active Menu Staging Canvas allowing users to organize their right-click menu via direct drag-and-drop reordering, insert custom system separators, delete or disable menu items, and automatically synchronize changes to `SharedStorageManager` with IPC dispatch.

**Blocked by:** 01 — Ordered Canvas Item Data Model & FinderSync Menu Builder, 04 — Action Library Pane & Reactive State Coordinator

**Status:** resolved

- [x] Active Menu canvas renders the linear sequence of active actions and separators with smooth drop targets.
- [x] Users can drag items up and down within the canvas to reorder them with smooth spring animations (`0.18s`).
- [x] Users can drag actions from the Action Library and drop them at specific index locations on the canvas.
- [x] "+ Add Separator" action inserts a system separator token at the chosen position.
- [x] Hovering or selecting an item reveals a quick remove/disable button (`trash` / `minus` symbol).
- [x] All canvas reordering and insertion operations immediately update `AppMenuStateCoordinator` and persist via IPC.

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements Seam B (Active Menu Staging Canvas & Direct Manipulation).
