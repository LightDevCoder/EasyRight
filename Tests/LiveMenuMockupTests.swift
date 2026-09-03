import SwiftUI
import AppKit

@main
struct LiveMenuMockupTests {
    @MainActor
    static func main() async {
        print("🧪 [Test] Running Issue 06 1:1 Real-Time Native Context Menu Mockup Tests...")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storage = SharedStorageManager(sharedContainerURLOverride: tempDir)
        let coordinator = AppMenuStateCoordinator(storage: storage)

        // MARK: 1. Mockup Geometry & Constants Verification
        print("  -> Testing Mockup Geometry Tokens & Constants...")
        assert(LiveMenuMockupView.menuWidth >= 220 && LiveMenuMockupView.menuWidth <= 250, "Menu width must be between 220 and 250pt")
        assert(LiveMenuMockupView.cornerRadius >= 8 && LiveMenuMockupView.cornerRadius <= 10, "Corner radius must be between 8 and 10pt")
        assert(LiveMenuMockupView.rowHeight >= 22 && LiveMenuMockupView.rowHeight <= 26, "Row height must be between 22 and 26pt")
        assert(LiveMenuMockupView.highlightRadius == 4, "Highlight pill corner radius must be 4pt matching macOS menus")
        print("     ✓ Menu geometry (width: \(LiveMenuMockupView.menuWidth)pt, radius: \(LiveMenuMockupView.cornerRadius)pt, row: \(LiveMenuMockupView.rowHeight)pt): PASSED")

        // MARK: 2. Menu Shortcut Mapping
        print("  -> Testing MenuShortcutMapper...")
        assert(MenuShortcutMapper.shortcut(for: "file_manage_copy_path") == "⌥⌘C", "Copy path shortcut mismatch")
        assert(MenuShortcutMapper.shortcut(for: "file_manage_cut") == "⌘X", "Cut shortcut mismatch")
        assert(MenuShortcutMapper.shortcut(for: "file_manage_paste") == "⌘V", "Paste shortcut mismatch")
        assert(MenuShortcutMapper.shortcut(for: "terminal_open_terminal") == "⌃⌥T", "Terminal shortcut mismatch")
        assert(MenuShortcutMapper.shortcut(for: "terminal_open_vscode") == "⌃⌥C", "VSCode shortcut mismatch")
        assert(MenuShortcutMapper.shortcut(for: "utility_toggle_hidden_files") == "⇧⌘.", "Toggle hidden shortcut mismatch")
        assert(MenuShortcutMapper.shortcut(for: "non_existent_action") == nil, "Unknown action should return nil shortcut")
        print("     ✓ Shortcut mapper: PASSED")

        // MARK: 3. Simulated Action Item Row Rendering (Default & Hovered)
        print("  -> Testing SimulatedActionItemRow rendering & hover state...")
        let sampleActionId = "file_manage_copy_path"
        let unhoveredRow = SimulatedActionItemRow(
            actionId: sampleActionId,
            coordinator: coordinator,
            isHovered: false
        )
        _ = unhoveredRow.body

        let hoveredRow = SimulatedActionItemRow(
            actionId: sampleActionId,
            coordinator: coordinator,
            isHovered: true
        )
        _ = hoveredRow.body
        print("     ✓ SimulatedActionItemRow (unhovered & hovered): PASSED")

        // MARK: 4. Simulated Separator Row Rendering
        print("  -> Testing SimulatedMenuSeparatorRow...")
        let sepRow = SimulatedMenuSeparatorRow()
        _ = sepRow.body
        print("     ✓ SimulatedMenuSeparatorRow: PASSED")

        // MARK: 5. Simulated Submenu Item Row Rendering
        print("  -> Testing SimulatedSubmenuItemRow (with actions & empty)...")
        let populatedSubmenuRow = SimulatedSubmenuItemRow(
            title: "开发终端",
            actionIds: ["terminal_open_terminal", "terminal_open_vscode"],
            coordinator: coordinator,
            isHovered: false
        )
        _ = populatedSubmenuRow.body

        let hoveredSubmenuRow = SimulatedSubmenuItemRow(
            title: "开发终端",
            actionIds: ["terminal_open_terminal", "terminal_open_vscode"],
            coordinator: coordinator,
            isHovered: true
        )
        _ = hoveredSubmenuRow.body

        let emptySubmenuRow = SimulatedSubmenuItemRow(
            title: "空目录",
            actionIds: [],
            coordinator: coordinator,
            isHovered: false
        )
        _ = emptySubmenuRow.body
        print("     ✓ SimulatedSubmenuItemRow: PASSED")

        // MARK: 6. Simulated Empty Menu Row
        print("  -> Testing SimulatedMenuEmptyRow...")
        let emptyRow = SimulatedMenuEmptyRow()
        _ = emptyRow.body
        print("     ✓ SimulatedMenuEmptyRow: PASSED")

        // MARK: 7. Reactive Updating & Zero-Lag Item Synchronization
        print("  -> Testing Reactive 0-lag updates with coordinator...")
        // Start from clear state
        coordinator.clearAll()
        assert(coordinator.canvasItems.isEmpty, "Canvas must be empty")

        let mockupWithEmptyState = LiveMenuMockupView(coordinator: coordinator)
        _ = mockupWithEmptyState.body

        // Add action item
        coordinator.insertAction(actionId: "file_manage_copy_path", at: 0)
        assert(coordinator.canvasItems.count == 1, "Canvas must have 1 item")
        assert(coordinator.canvasItems[0].actionId == "file_manage_copy_path", "Item 0 must match inserted action")

        // Add separator
        coordinator.addSeparator(at: 1)
        assert(coordinator.canvasItems.count == 2, "Canvas must have 2 items")
        assert(coordinator.canvasItems[1].isSeparator, "Item 1 must be separator")

        // Add submenu
        let submenu = MenuCanvasItem.submenu(title: "常用小工具", actionIds: ["utility_calculate_md5", "utility_text_to_qrcode"])
        coordinator.canvasItems.append(submenu)
        assert(coordinator.canvasItems.count == 3, "Canvas must have 3 items")
        assert(coordinator.canvasItems[2].isSubmenu, "Item 2 must be submenu")

        // Reorder
        coordinator.moveCanvasItem(fromIndex: 2, toIndex: 0)
        assert(coordinator.canvasItems[0].isSubmenu, "Submenu must now be at index 0")

        // Remove item
        coordinator.removeCanvasItem(at: 1)
        assert(coordinator.canvasItems.count == 2, "Canvas must now have 2 items")

        let populatedMockup = LiveMenuMockupView(coordinator: coordinator)
        _ = populatedMockup.body
        print("     ✓ Reactive Canvas synchronization: PASSED")

        // MARK: 8. Live Preview Toggle State
        print("  -> Testing Live Preview Presentation Toggle...")
        assert(coordinator.isLivePreviewPresented == true, "Live preview should default to true")
        coordinator.toggleLivePreview()
        assert(coordinator.isLivePreviewPresented == false, "Live preview should toggle to false")
        coordinator.toggleLivePreview()
        assert(coordinator.isLivePreviewPresented == true, "Live preview should toggle back to true")
        print("     ✓ Live preview toggle state: PASSED")

        // MARK: 9. Multi-Pane CanvasMainView & MainWindowView Integration
        print("  -> Testing CanvasMainView & MainWindowView full layout integration...")
        let defaultMockup = LiveMenuMockupView()
        _ = defaultMockup.body

        let canvasMainView = CanvasMainView(coordinator: coordinator)
        _ = canvasMainView.body

        let defaultCanvasMain = CanvasMainView()
        _ = defaultCanvasMain.body

        let mainWindow = MainWindowView(coordinator: coordinator, initialSection: .canvas)
        _ = mainWindow.body
        print("     ✓ Full View hierarchy instantiation: PASSED")

        print("🎉 ALL 1:1 REAL-TIME NATIVE CONTEXT MENU MOCKUP TESTS PASSED SUCCESSFULLY!")
    }
}
