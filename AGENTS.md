# AI Agent & Contributor Guide for EasyRight

Welcome to **EasyRight**! This document provides architectural context, security boundaries, and engineering guidelines for AI agents and human contributors working in this repository.

---

## 1. Project Philosophy & Constraints

- **Pure Native Swift & Zero Dependencies**: 100% written in Swift, SwiftUI, and AppKit. **No external third-party package dependencies** (via SPM or CocoaPods) are permitted. All capabilities rely strictly on macOS system APIs.
- **Ultra-Low Latency Injection**: The FinderSync extension (`EasyRightExtension`) runs directly inside the macOS Finder process. The context menu rendering critical path must execute in sub-milliseconds: **no synchronous disk I/O, no network calls, and no spawning of sub-processes** on the menu presentation thread.
- **Decoupled Dual-Process Architecture**:
  - `EasyRightExtension` captures user selection context and enqueues action events.
  - `EasyRight` (Host App) manages user settings, permissions, background worker tasks, and heavy file I/O operations.
  - Inter-process communication (IPC) uses atomic file-based queues and memory-mapped states backed by App Group shared containers.

---

## 2. Codebase Structure

```
.
├── Casks/                     # Homebrew Cask definition for distribution
├── Resources/                 # App icons, template documents (.docx, .xlsx, .pptx)
├── Scripts/                   # Build, install, uninstall, and verification scripts
│   ├── build.sh               # Main build pipeline (compiles Universal 2 app & DMG)
│   └── validate_cask.sh       # Homebrew Cask format and checksum validator
├── Sources/
│   ├── ActionVerifier/        # Action validation utility
│   ├── EasyRight/             # Host application
│   │   ├── Core/              # Core business models, actions, storage, and IPC
│   │   │   ├── Actions/       # Built-in context menu action implementations
│   │   │   ├── Logging/       # Unified OSLog diagnostics
│   │   │   ├── ActionConfigCache.swift
│   │   │   ├── DefaultActionRegistry.swift
│   │   │   ├── MenuLayout.swift
│   │   │   └── SharedStorageManager.swift
│   │   └── Views/             # SwiftUI user interface & active staging canvas
│   ├── EasyRightExtension/    # FIFinderSync context menu extension
│   └── EasyRightQuickService/ # Fallback macOS system services helper
├── Tests/                     # Unit, integration, and packaging regression tests
├── CHANGELOG.md               # Version changelog (Keep a Changelog format)
└── VERSION                    # Single source of truth for semantic versioning
```

---

## 3. Concurrency & IPC Guidelines

1. **State Synchronization**:
   - Configuration reads in `ActionConfigCache` utilize in-memory barriers (`queue.sync(flags: .barrier)`) combined with persistent updates in `SharedStorageManager`.
   - Action dispatching follows an atomic lease lifecycle: `Pending` -> `InFlight` -> `Acknowledge / Reclaim` to prevent event drops during process crashes.
2. **Swift 6 Concurrency**:
   - Adhere strictly to Sendable contracts (`Sendable`, `@unchecked Sendable`, and `@MainActor`).
   - UI mutations and window controllers must remain on the `@MainActor`.
   - Background runners (`BackgroundActionRunner`, `InteractiveActionRunner`) must isolate file operations from UI threads.

---

## 4. Permissions & Sandboxing

- **Host App & Extension Entitlements**: Defined in `entitlements/`. Both components run under App Sandbox protection.
- **Full Disk Access (FDA)**: FDA is strictly optional for general usage; it affects only protected system directories. Context menu rendering must not depend on FDA being granted.
- **Apple Events & Automation**: Used carefully for Finder refresh or system integrations with appropriate user consent prompts.

---

## 5. Development & Testing Commands

Before proposing or committing changes, verify with the following commands:

```bash
# 1. Run all unit and integration tests
swift test

# 2. Run structural and packaging tests
bash Tests/CaskStructureTests.sh
bash Tests/ReleaseWorkflowStructureTests.sh

# 3. Build Universal 2 application and DMG bundle
bash Scripts/build.sh
```

---

## 6. Versioning & Releases

- Version numbers follow [Semantic Versioning](https://semver.org/).
- The authoritative version is stored in the root `VERSION` file.
- Packaging scripts (`Scripts/build.sh`) and Homebrew definitions (`Casks/easyright.rb`) automatically read or validate against `VERSION`.
