# 01 — Ordered Canvas Item Data Model & FinderSync Menu Builder

**What to build:** An ordered menu canvas item data model supporting individual actions, native separators, and submenus, serialized via `SharedStorageManager` with IPC notification broadcasts, and consumed by `MenuLayout` / `FinderSync` to dynamically construct native Finder context menus with full fallback compatibility.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] `MenuCanvasItem` enum (action, separator, submenu) is defined with `Codable`, `Equatable`, and `Identifiable` compliance.
- [x] `SharedStorageManager` persists and retrieves the ordered canvas item list to `action_config.json` without data loss.
- [x] Modifying canvas configuration posts `guyue.RightClickAssistant.configChanged` via `DistributedNotificationCenter`.
- [x] `MenuLayout` parses `MenuCanvasItem` sequences into native `NSMenuItem` / `NSMenu` structures, creating proper separators and submenu hierarchies.
- [x] `FinderSync` preserves correct tag mapping and action dispatch when items are dynamically reordered.
- [x] Legacy configuration without ordered items falls back gracefully to default registry ordering.
- [x] Unit tests verify end-to-end serialization, deserialization, ordering preservation, and separator rendering.

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements Seam A (FinderSync Extension Host Boundary & Data Contract Expansion).
