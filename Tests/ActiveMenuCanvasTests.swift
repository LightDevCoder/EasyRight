import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct ActiveMenuCanvasTests {
    @MainActor
    static func main() async {
        print("🧪 [Test] Running Issue 05 Active Menu Staging Canvas Tests...")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storage = SharedStorageManager(sharedContainerURLOverride: tempDir)

        // MARK: 1. Coordinator & Canvas Initialization
        print("  -> Testing Coordinator & Canvas initial state...")
        let coordinator = AppMenuStateCoordinator(storage: storage)
        assert(!coordinator.canvasItems.isEmpty, "Canvas should have default items initially")
        let initialCount = coordinator.canvasItems.count
        print("     ✓ Canvas initialized with \(initialCount) items")

        // MARK: 2. MenuAction Target Scope Descriptions
        print("  -> Testing MenuAction target scope descriptions...")
        for action in coordinator.allActions {
            let scopeDesc = action.targetScopeDescription
            assert(!scopeDesc.isEmpty, "Target scope description should not be empty for \(action.actionId)")
        }
        print("     ✓ Target Scope descriptions: PASSED")

        // MARK: 3. Adding and Removing Separators
        print("  -> Testing Separator insertion & deletion...")
        coordinator.addSeparator(at: 0)
        assert(coordinator.canvasItems.count == initialCount + 1, "Canvas count should increase by 1")
        assert(coordinator.canvasItems[0].isSeparator, "First item must be separator")
        
        let sepId = coordinator.canvasItems[0].id
        coordinator.removeCanvasItem(id: sepId)
        assert(coordinator.canvasItems.count == initialCount, "Canvas count must revert to initialCount")
        print("     ✓ Separator insertion & removal: PASSED")

        // MARK: 4. Drag & Drop / Reordering Logic
        print("  -> Testing Drag-and-Drop Reordering within Canvas...")
        // Move item from index 0 to index 2
        let firstItem = coordinator.canvasItems[0]
        coordinator.moveCanvasItem(fromIndex: 0, toIndex: 2)
        assert(coordinator.canvasItems[2].id == firstItem.id, "First item should have moved to index 2")

        // Reorder via handleDrop with item.id
        let itemToMove = coordinator.canvasItems[2]
        coordinator.handleDrop(identifier: itemToMove.id, at: 0)
        assert(coordinator.canvasItems[0].id == itemToMove.id, "Item dropped at 0 should now be at index 0")
        print("     ✓ Canvas item reordering: PASSED")

        // MARK: 5. Dropping Action from Library (Unstaged & Staged)
        print("  -> Testing dropping Action from ActionLibraryView...")
        // Remove an action first
        let sampleActionId = coordinator.allActions[0].actionId
        coordinator.removeAction(actionId: sampleActionId)
        assert(!coordinator.isActionStaged(actionId: sampleActionId), "Action should not be staged")

        // Drop unstaged action at index 1
        coordinator.handleDrop(identifier: sampleActionId, at: 1)
        assert(coordinator.isActionStaged(actionId: sampleActionId), "Action should now be staged")
        assert(coordinator.canvasItems[1].actionId == sampleActionId, "Action should be inserted at index 1")

        // Drop already staged action to reorder it to index 0
        coordinator.handleDrop(identifier: sampleActionId, at: 0)
        assert(coordinator.canvasItems[0].actionId == sampleActionId, "Staged action dropped at 0 should move to index 0")
        print("     ✓ Library action drop handling: PASSED")

        // MARK: 6. Submenu Canvas Item Support
        print("  -> Testing Submenu item in Canvas...")
        let submenuItem = MenuCanvasItem.submenu(title: "测试开发工具", actionIds: ["open_terminal", "open_vscode"])
        coordinator.canvasItems.append(submenuItem)
        coordinator.scheduleSave()
        assert(coordinator.canvasItems.last?.isSubmenu == true, "Last item should be submenu")
        assert(coordinator.canvasItems.last?.title == "测试开发工具", "Submenu title must match")
        assert(coordinator.canvasItems.last?.actionIds.count == 2, "Submenu actionIds count must be 2")

        coordinator.removeCanvasItem(id: submenuItem.id)
        assert(coordinator.canvasItems.last?.isSubmenu == false, "Submenu should be removed")
        print("     ✓ Submenu support: PASSED")

        // MARK: 7. Reset to Default & Clear All & Add Recommended
        print("  -> Testing Clear All, Reset to Default, Add Recommended...")
        coordinator.clearAll()
        assert(coordinator.canvasItems.isEmpty, "Canvas should be empty after clearAll")
        assert(coordinator.stagedActionCount == 0, "Staged count should be 0")

        coordinator.addRecommendedActions()
        assert(!coordinator.canvasItems.isEmpty, "Canvas should have items after addRecommendedActions")
        assert(coordinator.stagedActionCount > 0, "Staged action count should be > 0")

        coordinator.resetToDefault()
        assert(coordinator.canvasItems.count == storage.defaultCanvasItems().count, "Canvas count should match default items count")
        print("     ✓ Clear, Reset, and Recommended: PASSED")

        // MARK: 8. Row Selection
        print("  -> Testing Row Selection...")
        coordinator.selectedActionId = sampleActionId
        assert(coordinator.selectedActionId == sampleActionId, "Selected action ID should match")
        assert(coordinator.selectedAction?.actionId == sampleActionId, "Selected action object should match")
        coordinator.selectedActionId = nil
        assert(coordinator.selectedActionId == nil, "Selection should clear")
        print("     ✓ Row Selection: PASSED")

        // MARK: 9. Persistence & Storage Flush
        print("  -> Testing IPC & Storage synchronization...")
        coordinator.flushPendingSave()
        let stored = storage.getCanvasItems()
        assert(stored == coordinator.canvasItems, "Persisted canvas items must match coordinator canvas items")
        print("     ✓ Persistence & IPC: PASSED")

        // MARK: 10. SwiftUI Views Instantiation
        print("  -> Testing SwiftUI Views Instantiation...")
        let canvasView = ActiveMenuCanvasView(coordinator: coordinator)
        _ = canvasView.body

        let defaultCanvasView = ActiveMenuCanvasView()
        _ = defaultCanvasView.body

        let actionRow = CanvasActionRowView(
            coordinator: coordinator,
            actionId: sampleActionId,
            itemId: "action:\(sampleActionId)",
            index: 0,
            totalCount: coordinator.canvasItems.count
        )
        _ = actionRow.body

        let sepRow = CanvasSeparatorRowView(
            coordinator: coordinator,
            itemId: "separator:\(UUID().uuidString)",
            index: 0,
            totalCount: coordinator.canvasItems.count
        )
        _ = sepRow.body

        let subRow = CanvasSubmenuRowView(
            coordinator: coordinator,
            itemId: "submenu:\(UUID().uuidString)",
            title: "常用工具",
            actionIds: [sampleActionId],
            index: 0,
            totalCount: coordinator.canvasItems.count
        )
        _ = subRow.body

        let canvasMainView = CanvasMainView(coordinator: coordinator)
        _ = canvasMainView.body

        let mainWindow = MainWindowView(coordinator: coordinator, initialSection: .canvas)
        _ = mainWindow.body
        print("     ✓ SwiftUI Views instantiation: PASSED")

        print("🎉 ALL ACTIVE MENU CANVAS & REORDERING TESTS PASSED SUCCESSFULLY!")
    }
}
