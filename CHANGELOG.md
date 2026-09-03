# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## v0.1.0 — 2026-09-03

### Initial Release

Welcome to the initial public release of **EasyRight** (`v0.1.0`)!

#### Added
- **30+ Native Finder Context Actions**:
  - Quick file creation (`.txt`, `.md`, Word `.docx`, Excel `.xlsx`, PowerPoint `.pptx`, and templates).
  - Developer utilities: Open in Terminal / iTerm2 / Warp, open in VS Code / Cursor / Sublime Text, Git root navigation.
  - File and path utilities: Shell-safe path copy, POSIX path copy, file hash calculation (MD5/SHA1/SHA256), image-to-Base64 conversion, and hidden file toggle.
  - Contextual filtering: Automatic intelligent activation based on selection type (blank area, single file, multiple files, folders, or file extensions).
- **Custom App Actions**:
  - Add any installed macOS application (Keka, Typora, IINA, etc.) to the Finder context menu directly from Settings.
  - Configurable contextual activation rules with custom file extension filters.
- **Active Menu Staging Canvas**:
  - Modern acrylic visual layout designer: drag, reorder, group, and toggle actions with real-time feedback.
  - Live native Finder menu preview reflecting custom changes with sub-millisecond fidelity.
- **Diagnostics & Health Capsule**:
  - Ambient health monitoring and diagnostic drawer to verify Full Disk Access, FinderSync IPC heartbeats, and queue health.
- **Bilingual Interface & Instant Language Switching**:
  - Global real-time language switching (Simplified Chinese / English) in Preferences with dynamic in-place UI re-rendering without requiring app restart.
- **Dynamic Layout Presets & Quick Access**:
  - One-click starter preset switcher (Lite, Dev, Max) directly accessible by clicking the top-left title or from Preferences.
  - Dynamic responsive title badge (`EasyRight [Lite]`, `[Dev]`, `[Max]`, or `[User]` when customized).
- **Refined Light App Icon & DMG Custom Volume Icon**:
  - Crisp, modern light-themed app icon with transparent squircle shadow.
  - Native `.VolumeIcon.icns` injection with custom icon attribute enabled for the DMG installer.
- **Decoupled Architecture**:
  - Dual-process model: High-performance `FIFinderSync` extension decoupled from the host App for zero-lag context-menu display.
  - Zero external dependencies, written 100% in Swift, SwiftUI, and AppKit.
  - Universal 2 binary supporting both Apple Silicon (`arm64`) and Intel (`x86_64`) Macs.
