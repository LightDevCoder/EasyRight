# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## v0.1.1 — 2026-09-16

### Seamless Config Persistence & macOS 27 Golden Gate Adaptation

#### Added
- **Seamless Dual-Write Configuration Mirroring**:
  - Automatically mirrors all configuration changes (`config.json`, `action_config.json`, `custom_app_actions.json`) to durable host storage at `~/Library/Application Support/EasyRight/ConfigBackup/`.
  - Zero-touch disaster recovery on launch: automatically restores existing configurations if the extension sandbox container is wiped during cleaning, uninstallation, or reinstallation.
  - Automatic initial backup backfill for existing users upon first launch.
- **Graded Uninstall Protection**:
  - `Scripts/uninstall.sh` now preserves user configuration backups by default, preventing accidental loss during maintenance. Added `--purge` flag for complete cleanup.

#### Fixed & Improved
- **macOS 27 (Golden Gate) & Swift 6 Compatibility**:
  - Fixed CLT-only build incompatibility in `Scripts/build.sh` by automatically detecting missing `SwiftUIMacros` and falling back to a compatible SDK.
  - Added architecture targeting support (`TARGET_ARCHS`) in `build.sh`.
  - Fixed Swift 6 compiler warnings in `MenuBarController`, `AmbientHealthCapsule`, and `OnboardingView`.
  - Added comprehensive test suite `ConfigBackupRecoveryTests` covering dual-write mirroring, auto-restoration, and corruption defense.

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
