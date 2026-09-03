import SwiftUI
import AppKit

@main
struct ActionLibraryAndCoordinatorTests {
    @MainActor
    static func main() async {
        print("🧪 [Test] Running Issue 04 Action Library & State Coordinator Tests...")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storage = SharedStorageManager(sharedContainerURLOverride: tempDir)

        // MARK: 1. Initialization & Initial State
        print("  -> Testing Coordinator initialization & initial state...")
        let coordinator = AppMenuStateCoordinator(storage: storage)
        assert(!coordinator.allActions.isEmpty, "allActions should contain default registry actions")
        assert(!coordinator.canvasItems.isEmpty, "canvasItems should be populated with defaults")
        assert(coordinator.selectedActionId == nil, "selectedActionId should initially be nil")
        assert(coordinator.selectedAction == nil, "selectedAction should initially be nil")
        assert(coordinator.searchQuery.isEmpty, "searchQuery should initially be empty")
        assert(coordinator.filterText.isEmpty, "filterText should initially be empty")
        assert(coordinator.selectedCategory == nil, "selectedCategory should initially be nil (All)")
        print("     ✓ Initialization: PASSED")

        // MARK: 2. Two-way searchQuery / filterText synchronization
        print("  -> Testing searchQuery and filterText sync...")
        coordinator.searchQuery = "终端"
        assert(coordinator.filterText == "终端", "filterText must sync with searchQuery")
        coordinator.filterText = "新建"
        assert(coordinator.searchQuery == "新建", "searchQuery must sync with filterText")
        coordinator.searchQuery = ""
        assert(coordinator.filterText == "", "clearing searchQuery must clear filterText")
        print("     ✓ Search Query Sync: PASSED")

        // MARK: 3. Category & Text Filtering
        print("  -> Testing category and text filtering...")
        // All actions initially
        assert(coordinator.filteredActions.count == coordinator.allActions.count, "When query/category empty, all actions returned")

        // Filter by category: New File
        coordinator.selectedCategory = .newFile
        assert(!coordinator.filteredActions.isEmpty, "New file actions should not be empty")
        for action in coordinator.filteredActions {
            assert(action.category == .newFile, "Filtered actions must match newFile category")
        }

        // Filter by category: Terminal
        coordinator.selectedCategory = .terminal
        assert(!coordinator.filteredActions.isEmpty, "Terminal actions should not be empty")
        for action in coordinator.filteredActions {
            assert(action.category == .terminal, "Filtered actions must match terminal category")
        }

        // Filter by text search
        coordinator.selectedCategory = nil
        coordinator.searchQuery = "txt"
        let txtFiltered = coordinator.filteredActions
        assert(!txtFiltered.isEmpty, "Should find txt action")
        assert(txtFiltered.contains { $0.actionId.contains("txt") || $0.localizedTitle.localizedCaseInsensitiveContains("txt") })

        // Combined filtering
        coordinator.selectedCategory = .utility
        coordinator.searchQuery = "MD5"
        let md5Filtered = coordinator.filteredActions
        assert(md5Filtered.count == 1, "Should find exactly 1 MD5 utility action")
        assert(md5Filtered[0].category == .utility)

        // Reset
        coordinator.selectedCategory = nil
        coordinator.searchQuery = ""
        print("     ✓ Filtering & Search: PASSED")

        // MARK: 4. Staged State & Toggle
        print("  -> Testing staged state detection & toggleAction...")
        let sampleActionId = coordinator.allActions[0].actionId

        // Initially staged
        assert(coordinator.isActionStaged(actionId: sampleActionId) == true, "Default actions are staged")

        // Toggle off
        coordinator.toggleAction(actionId: sampleActionId)
        assert(coordinator.isActionStaged(actionId: sampleActionId) == false, "Toggled action should no longer be staged")

        // Toggle on
        coordinator.toggleAction(actionId: sampleActionId)
        assert(coordinator.isActionStaged(actionId: sampleActionId) == true, "Toggled action should be staged again")
        print("     ✓ Toggle & Staged check: PASSED")

        // MARK: 5. Separator & Canvas Items Manipulation
        print("  -> Testing separator insertion & reordering...")
        let initialCount = coordinator.canvasItems.count
        coordinator.addSeparator(at: 0)
        assert(coordinator.canvasItems.count == initialCount + 1, "Canvas count should increase by 1 after adding separator")
        assert(coordinator.canvasItems[0].isSeparator, "First item should be separator")

        // Remove separator at index 0
        let sepId = coordinator.canvasItems[0].id
        coordinator.removeCanvasItem(id: sepId)
        assert(coordinator.canvasItems.count == initialCount, "Canvas count should return to initialCount after removing separator")

        // Add separator at end
        coordinator.addSeparator()
        assert(coordinator.canvasItems.last?.isSeparator == true, "Last item should be separator")

        // Move item
        let lastIndex = coordinator.canvasItems.count - 1
        coordinator.moveCanvasItem(fromOffsets: IndexSet(integer: lastIndex), toOffset: 0)
        assert(coordinator.canvasItems[0].isSeparator, "Moved item should now be at index 0")

        // Remove item at index
        coordinator.removeCanvasItem(at: 0)
        assert(coordinator.canvasItems.count == initialCount, "Canvas count should be back to initialCount")
        print("     ✓ Separator & Canvas Manipulation: PASSED")

        // MARK: 6. Inspector Selection
        print("  -> Testing Inspector selection...")
        coordinator.selectedActionId = sampleActionId
        assert(coordinator.selectedAction?.actionId == sampleActionId, "selectedAction should match selectedActionId")
        coordinator.selectedActionId = nil
        assert(coordinator.selectedAction == nil, "selectedAction should be nil when selectedActionId is nil")
        print("     ✓ Inspector Selection: PASSED")

        // MARK: 7. Persistence & Reloading
        print("  -> Testing persistence & reloadFromStorage...")
        coordinator.flushPendingSave()

        let storedItems = storage.getCanvasItems()
        assert(storedItems == coordinator.canvasItems, "Storage items must match coordinator canvasItems after flush")

        // Simulate external change in storage
        let modifiedItems: [MenuCanvasItem] = [
            .action(actionId: "custom_external_action"),
            .separator(id: UUID())
        ]
        storage.saveCanvasItems(modifiedItems, postNotification: false)

        coordinator.reloadFromStorage()
        assert(coordinator.canvasItems == modifiedItems, "reloadFromStorage should sync coordinator with external storage")
        print("     ✓ Persistence & Reload: PASSED")

        // MARK: 8. ActionLibraryView Instantiation
        print("  -> Testing ActionLibraryView UI instantiation...")
        let libraryView = ActionLibraryView(coordinator: coordinator)
        _ = libraryView.body

        let defaultLibraryView = ActionLibraryView()
        _ = defaultLibraryView.body

        let rowView = ActionLibraryRowView(coordinator: coordinator, action: coordinator.allActions[0])
        _ = rowView.body
        print("     ✓ ActionLibraryView UI instantiation: PASSED")

        print("🎉 ALL ACTION LIBRARY & COORDINATOR TESTS PASSED SUCCESSFULLY!")
    }
}
