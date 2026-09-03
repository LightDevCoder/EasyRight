# 08 — Ambient Health Status Capsule & Slide-out Diagnostic Drawer

**What to build:** An ambient health status capsule in the studio header and menu bar accessory summarizing system state (Full Disk Access, FinderSync registration, Heartbeat), accompanied by a slide-out diagnostic drawer offering one-click automated repair, permission deep-linking, and Finder restart.

**Blocked by:** 02 — Menu Bar Resident Controller & Accessory Lifecycle, 03 — Acrylic Studio Window Shell & Design Token System

**Status:** resolved

- [x] Ambient pill badge in window header displays live status: Healthy (Green), Warning (Amber), or Error (Red).
- [x] Status updates asynchronously using `FullDiskAccessChecker`, `FinderExtensionDiagnostics`, and `ExtensionHeartbeat`.
- [x] Clicking the status capsule slides out a diagnostic drawer from the right edge with detailed diagnostic checks.
- [x] Diagnostic drawer includes "Open System Settings..." deep-link buttons for Full Disk Access and Extensions panes.
- [x] Provides a prominent "One-Click Self-Repair & Restart Finder" button invoking `SystemReloader` and re-registering extension bundles.
- [x] Health status is mirrored in the Menu Bar accessory dropdown.

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements Ambient Health Status Capsule & Diagnostic Drawer.
