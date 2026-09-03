# 02 — Menu Bar Resident Controller & Accessory Lifecycle

**What to build:** An unobtrusive menu bar status item (`NSStatusItem`) that serves as the resident entry point for the utility, providing a sleek popover/dropdown with quick status, quick action toggles, a one-click Finder restart action, and a preferences launcher, while handling Dock-free background execution and dynamic activation policy switching.

**Blocked by:** None — can start immediately

**Status:** resolved

- [x] `MenuBarController` manages an `NSStatusItem` displaying an adaptive monochrome SF Symbol in the system menu bar.
- [x] Application starts with `.accessory` activation policy by default, ensuring no persistent icon in the macOS Dock.
- [x] Clicking the status item reveals a CleanShot-style native menu/popover with extension health status, quick toggles, Finder reload, and Settings trigger.
- [x] Triggering "Settings / Preferences" smoothly activates the application to `.regular` policy and brings the studio window to front.
- [x] Closing or minimizing the studio window transitions the activation policy back to `.accessory` without terminating the process.
- [x] One-click "Restart Finder" invokes `SystemReloader` safely and displays an ambient status indicator.

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements Seam C (System Accessory & Lifecycle).
