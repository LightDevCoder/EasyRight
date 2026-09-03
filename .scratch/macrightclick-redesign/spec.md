# SPEC — Modern macOS Finder Context Menu Utility Redesign

## Problem Statement

The upstream MacRightClick project (`repo_source/`) provides functional Finder context menu extensions and system service integrations for macOS, including file creation templates, clipboard management, terminal/editor launchers, and cryptographic hashing utilities (`repo_source/Sources/RightClickAssistant/Core/DefaultActionRegistry.swift:7-38`).

However, the current host application and user interaction suffer from severe usability, architectural, and visual shortcomings:
1. **Generic iOS-Ported "Card" Interface**: The host window relies on `.formStyle(.grouped)` inside standard SwiftUI `Form` containers (`repo_source/Sources/RightClickAssistant/Views/ActionsSettingsView.swift:74`), resulting in oversized, clumsy gray cards, excessive outer margins, and poor desktop ergonomics.
2. **Debug-Centric Information Architecture**: The primary navigation splits into five top-level tabs (`repo_source/Sources/RightClickAssistant/Views/ContentView.swift:4-10`), elevating developer internals such as raw PluginKit state queries, heartbeat JSON counters, and event queue ages directly into the user's primary workflow.
3. **Rigid Sorting and Lack of Organization Freedom**: Context menu actions can only be displayed as a flat alphabetical list or locked within hardcoded category groups (`repo_source/Sources/RightClickAssistant/Core/MenuLayout.swift:8-19`). Users cannot reorder actions, insert custom separators, or prioritize their highest-frequency workflows.
4. **Absence of Visual Feedback and Context Preview**: Toggling or enabling actions provides no visual spatial awareness; users must navigate to Finder and right-click on disk items to verify their menu structure.
5. **Intrusive Application Lifecycle**: The host operates as a standard foreground window application that clutters the macOS Dock (`repo_source/Sources/RightClickAssistant/AppDelegate.swift:10-40`), rather than living as a modern, lightweight menu bar utility (in the style of CleanShot X or Ice).

## Solution

Transform the project into a professional, high-density macOS utility featuring a Raycast-inspired translucent acrylic design language and a CleanShot X / Ice-style resident menu bar architecture:

1. **Menu Bar Resident Accessory (`NSStatusItem`)**: The application operates unobtrusively in the menu bar with zero Dock clutter during background operation. A click reveals quick status, quick action toggles, a one-click Finder restart action, and an entry to Preferences.
2. **Unified Acrylic Configuration Studio**: A desktop-tuned window (`880×580 pt`) utilizing native macOS vibrancy materials (`NSVisualEffectView` with `.behindWindow` blending) and razor-thin `0.5pt` borders (`Color.primary.opacity(0.08)`), strictly respecting Apple's dynamic semantic color system for seamless Dark/Light mode switching.
3. **Dual-Pane Action Canvas (Library + Active Menu)**:
   - **Action Library (Left Pane)**: Fast searchable repository of all built-in actions with category chips, state tags, and instant `+` enable actions.
   - **Active Menu Staging (Center/Right Pane)**: Direct-manipulation workspace displaying the exact active menu layout. Supports freeform drag-and-drop reordering, custom system divider insertions, and submenu assignment.
4. **1:1 Real-Time Native Context Menu Mockup**: An interactive, pixel-perfect simulated `NSMenu` preview component running alongside the canvas, updating at 60fps as actions, order, and separators change.
5. **Contextual Inspector Panel**: Selecting an action opens a lightweight inspector revealing target availability rules (file vs. directory vs. container/blank desktop), associated application bindings, and action-specific parameters.
6. **Ambient Health Status Capsule & Diagnostic Drawer**: System health (Full Disk Access, FinderSync extension registration, heartbeat) is summarized in an ambient status capsule in the window header/footer. Clicking it reveals a slide-out diagnostic tray with a one-click repair and Finder reload action.
7. **Clean 3-Step First-Run Onboarding**: First launch opens a focused onboarding sheet guiding the user through system extension authorization, auto-detecting readiness, and offering curated starting presets (Minimalist, Developer, Power User).

## User Stories

1. As a macOS user, I want the utility to live in my menu bar without cluttering the Dock, so that my desktop workspace remains clean.
2. As a power user, I want to freely drag and drop right-click actions into my preferred order, so that my most frequent actions appear right under my mouse cursor.
3. As a user, I want to insert custom horizontal separators between menu items, so that I can group related workflows visually in the native Finder menu.
4. As a user, I want to see a real-time, pixel-accurate preview of the Finder context menu inside the configuration window, so that I know exactly how my changes look without opening Finder.
5. As a developer, I want to filter the Action Library by category (New File, File Manage, Terminal/IDE, Utilities) and search by keyword, so that I can quickly toggle actions I need.
6. As a user, I want to click any action to inspect its activation conditions (e.g. only on folders, only on images, or on empty desktop space), so that I understand when it will be visible.
7. As a user, I want all configuration changes (reordering, toggling, dividers) to persist immediately and notify Finder via IPC, so that I never have to search for a "Save" button.
8. As a user, I want to click the menu bar status icon to quickly restart Finder or check extension status, so that I can recover immediately if macOS drops the extension connection.
9. As a new user, I want a concise 3-step setup guide on first launch, so that I can grant Full Disk Access and enable the FinderSync extension with minimum friction.
10. As a user working in low-light environments, I want the entire UI to adhere strictly to macOS system dark/light appearances with translucent vibrancy blur, so that the utility feels indistinguishable from a native macOS Sonoma/Sequoia system tool.
11. As a user experiencing extension issues, I want an ambient status capsule that flags missing permissions and provides a one-click repair drawer, so that technical troubleshooting remains accessible without dominating daily use.

## Implementation Decisions

### Seam Sketch & Architecture
The redesign maintains three strictly decoupled seams:
- **Seam A (FinderSync Extension Host Boundary)**: `SharedStorageManager` and the distributed IPC notification center (`guyue.RightClickAssistant.configChanged`). The internal data contract for `action_config.json` is expanded to store ordered menu items (including separator tokens) rather than a simple set of enabled flags. `FinderMenuLayoutBuilder` consumes this sequence to populate the native `NSMenu`.
- **Seam B (Host Application Presentation & State)**: Replaces `ContentView.swift` and `ActionsSettingsView.swift` with an integrated architecture:
  - `AppMenuStateCoordinator`: `@Observable` / `ObservableObject` managing the active menu item sequence, library filtering, inspector selection, and optimistic persistence.
  - `MainWindowView`: Unified toolbar, status capsule, and segment router (`Actions Canvas`, `Preferences`, `System Health`).
  - `ActionsCanvasView`: Dual-column layout hosting `ActionLibraryList`, `ActiveMenuOutlineView`, `LiveMenuMockupView`, and `ActionInspectorPanel`.
- **Seam C (System Accessory & Lifecycle)**: `MenuBarController` manages the `NSStatusItem` in the macOS system menu bar, providing quick popover access and lifecycle coordination (`NSApp.setActivationPolicy(.accessory)` vs `.regular` when the main window is displayed).

### Data Contract Expansion
The configuration schema in `SharedStorageManager` is extended from simple boolean toggles to an ordered node array:
```swift
public enum MenuCanvasItem: Codable, Equatable, Identifiable {
    case action(actionId: String)
    case separator(id: UUID)
    case submenu(id: UUID, title: String, actionIds: [String])
}
```
`FinderSync` parses this sequence directly:
- `action(id)` -> creates `NSMenuItem` via `ActionTagMapper`.
- `separator` -> creates `NSMenuItem.separator()`.
- `submenu` -> creates a nested `NSMenu`.
Backwards compatibility is preserved: if no ordered list exists, `FinderMenuLayoutBuilder` falls back to the legacy default registry.

### Component Styling & Visual Tokens
- **Vibrancy**: Window background wrapped in `VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)`.
- **Dividers & Strokes**: Hairline borders using `Color(nsColor: .separatorColor)` or `Color.primary.opacity(0.08)`.
- **Row Density**: Standard row height pegged to `38 pt` with `16×16 pt` SF Symbols rendered with `.hierarchical` monochrome shading.
- **Micro-Animations**: Transitions on reorder and drawer toggle capped at `0.18s` with `spring(response: 0.22, dampingFraction: 0.82)`.

## Testing / Verification Decisions

1. **Menu Layout Builder Verification (`MenuLayoutTests.swift`)**:
   - Verify that arbitrary sequences of `MenuCanvasItem` (actions, custom separators, submenus) serialize to and deserialize from `SharedStorageManager` without data loss.
   - Verify that disabled actions or missing application dependencies are filtered out gracefully during `NSMenu` construction.
2. **IPC & Storage Synchronization Tests**:
   - Verify that modifying an action's position or inserting a separator in the UI triggers immediate write to the shared container and posts `configChanged` via `DistributedNotificationCenter`.
3. **FinderSync Action Tag Mapping Tests**:
   - Verify that dynamic reordering does not corrupt `FinderSync.ActionTagMapper` integer tags or break action dispatching when items are selected in Finder.
4. **AppKit / Lifecycle Manual Verification Checklist**:
   - Verify zero Dock icon footprint when running in background accessory mode.
   - Verify seamless transition to regular window mode when preferences are triggered from menu bar.
   - Verify pixel-accurate alignment of the simulated `NSMenu` against an actual native macOS right-click menu.
   - Verify dark and light theme switching across macOS system preference changes without contrast degradation.

## Out of Scope

1. **Custom Finder Context Menu CSS / Styling**: macOS AppKit strictly limits `FIFinderSync` menus to standard `NSMenuItem` controls; any attempt to inject custom HTML, CSS, or non-native views into the Finder popup is forbidden by macOS sandboxing and is explicitly rejected.
2. **Custom Scripting / Plugin Engine**: The utility will not include an in-app JavaScript/Lua scripting engine or third-party extension marketplace; actions are built-in native Swift actions.
3. **Arbitrary Shell Script Exposer**: Arbitrary custom shell command creation via GUI is deferred to avoid security surface expansion and sandbox permission regressions.
4. **Cloud Storage Synchronization of User Config**: Configuration stays local to the macOS sandbox app group container.

## Further Notes

- **Preserved Core Assets**: All functional action implementations (`NewFileAction`, `FileManageAction`, `TerminalOpenAction`, `UtilityAction`, `PathCopyService`) in `repo_source/Sources/RightClickAssistant/Core/` are retained without behavioral regression.
- **Dependency Management**: The project continues using Swift Package Manager (SPM) without introducing bloated external UI dependencies; all visual enhancements are implemented using native SwiftUI and AppKit primitives.

---

# SPEC ADDENDUM — Custom External Application Actions (Open With / Processing)

## 1. Problem & Objectives
While EasyRight ships with 30 high-frequency built-in actions (including select editors like VS Code, Cursor, and Sublime Text), users frequently need right-click context menu integration for their own suite of installed macOS applications (such as Keka for archive compression/extraction, Typora for Markdown, IINA/VLC for media playback, or specialized design and developer tools). Hardcoding each third-party app in source code causes maintenance churn and fails to cover varied user workflows.

This module introduces **Custom External Application Actions (`CustomAppAction`)**:
- Allows users to select any installed application (`.app`) from `/Applications` or custom locations.
- Automatically resolves the application's bundle identifier, display title, and icon.
- Enables configurable context-matching rules (e.g. any file/directory, directories only, files only, or matching specific file extensions such as `.zip,.7z,.rar` for Keka).
- Integrates seamlessly into the native Finder context menu and the Active Menu Staging Canvas without breaking or modifying the 30 existing built-in actions.

## 2. Architecture & Seam Integration

### 2.1 Data Model (`CustomAppAction`)
```swift
public enum CustomAppTargetFilter: Codable, Equatable, Sendable {
    case all                           // All files and folders
    case directoriesOnly               // Directories only (ideal for IDEs, project tools)
    case filesOnly                     // Non-directory files only
    case extensions([String])          // Specific extensions (e.g. ["zip", "7z", "rar", "tar", "gz"])
}

public struct CustomAppAction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String            // Menu title (e.g. "使用 Keka 压缩/解压" or "在 Typora 中打开")
    public var bundleIdentifier: String
    public var appPath: String         // Path to .app bundle
    public var targetFilter: CustomAppTargetFilter
    public var isEnabled: Bool
    public var createdAt: Date
}
```

### 2.2 Execution Seam (`CustomAppOpenAction: MenuAction`)
- Dynamic instance implementing the `MenuAction` protocol.
- `actionId`: `"easyright.action.customapp.<UUID>"`.
- `isAvailable(for:targetURLs, isContainer:)`:
  - Validates that target URLs match `targetFilter`.
  - Verifies that the associated application is installed via `InstalledAppRegistry`.
- `submit(targetURLs:completion:)`:
  - Dispatches `NSWorkspace.shared.open(targetURLs, withApplicationAt: appURL, configuration: ...)` asynchronously.
  - Displays HUD status feedback on success or failure without requiring AppleScript or Automation permissions.

### 2.3 Storage & Notification Seam
- Persisted in `SharedStorageManager` via `custom_app_actions.json` inside the shared App Group / Extension container.
- Updating custom actions broadcasts `SharedStorageManager.actionConfigChangedNotification` across processes.
- `ActionDispatcher` registers dynamic actions on startup and upon receiving change notifications.
- `DefaultActionRegistry.makeActions()` remains pure and deterministic (producing the 30 built-in actions), while `ActionDispatcher` and `FinderSync` compose built-ins with dynamic user-defined custom actions.

### 2.4 User Interface
- A dedicated **"自定义应用" (Custom Apps)** tab/section in the Settings configuration studio.
- Native `NSOpenPanel` restricted to application bundles (`.app`) for adding new applications.
- Inline editing for menu label, activation scope (all / folders / files / file extensions), and enable/disable toggles.

