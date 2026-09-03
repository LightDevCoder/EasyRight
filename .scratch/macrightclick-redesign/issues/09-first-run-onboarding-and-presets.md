# 09 — First-Run 3-Step Onboarding Guide & Presets

**What to build:** A CleanShot-style 3-step onboarding flow presented on initial launch, walking new users through feature introduction, automated extension permission verification, and starter preset configuration (Minimalist, Developer, Power User), smoothly transitioning into the main studio.

**Blocked by:** 01 — Ordered Canvas Item Data Model & FinderSync Menu Builder, 04 — Action Library Pane & Reactive State Coordinator, 08 — Ambient Health Status Capsule & Slide-out Diagnostic Drawer

**Status:** resolved

- [x] First launch detection displays a clean 3-step onboarding modal sheet (`NSVisualEffectView` vibrancy).
- [x] Step 1 (Welcome): High-level feature showcase with concise graphics and modern typography.
- [x] Step 2 (Permissions): Live auto-polling status indicators for Full Disk Access and FinderSync Extension enablement with direct link buttons.
- [x] Step 3 (Preset Selection): Offers 3 curated starter presets (Minimalist: 4 essentials; Developer: Terminal/IDE/Hash/Paths; Power User: Full suite with organized separators).
- [x] Selecting a preset populates the `SharedStorageManager` canvas items and triggers IPC sync.
- [x] Completing onboarding sets `hasCompletedOnboarding` flag and smoothly navigates into the main studio canvas.

## Comments

Source: .scratch/macrightclick-redesign/spec.md. Implements 3-Step First-Run Onboarding & Presets.
