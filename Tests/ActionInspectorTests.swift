import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct ActionInspectorTests {
    @MainActor
    static func main() async {
        print("🧪 [Test] Running Issue 07 Contextual Action Inspector Panel Tests...")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storage = SharedStorageManager(sharedContainerURLOverride: tempDir)
        let coordinator = AppMenuStateCoordinator(storage: storage)

        // MARK: 1. ActionTargetScope Enums & Model Tests
        print("  -> Testing ActionTargetScope & ActionScopeAvailability model...")
        assert(ActionTargetScope.allCases.count == 4, "Must have 4 target scopes")
        for scope in ActionTargetScope.allCases {
            assert(!scope.displayName.isEmpty, "Scope display name should not be empty")
            assert(!scope.iconName.isEmpty, "Scope icon name should not be empty")
            assert(!scope.scopeDescription.isEmpty, "Scope description should not be empty")
        }
        print("     ✓ Target Scopes Enum verification: PASSED")

        // MARK: 2. Target Scope Availabilities across all Action Categories
        print("  -> Testing targetScopeAvailabilities across action categories...")

        // 2a. New File Action
        let newTxtAction = NewFileAction(fileType: .txt)
        let newTxtScopes = newTxtAction.targetScopeAvailabilities
        assert(newTxtScopes.count == 4, "Should evaluate all 4 scopes")
        assert(newTxtScopes.first(where: { $0.scope == .singleFile })?.isSupported == true, "NewFile should support single file")
        assert(newTxtScopes.first(where: { $0.scope == .multipleFiles })?.isSupported == true, "NewFile should support multiple files")
        assert(newTxtScopes.first(where: { $0.scope == .directory })?.isSupported == true, "NewFile should support directory")
        assert(newTxtScopes.first(where: { $0.scope == .blankArea })?.isSupported == true, "NewFile should support blank area")
        print("     ✓ NewFileAction scopes: PASSED")

        // 2b. Terminal Open Action
        let termAction = TerminalOpenAction(type: .terminal)
        let termScopes = termAction.targetScopeAvailabilities
        assert(termScopes.first(where: { $0.scope == .singleFile })?.isSupported == true, "Terminal should support single file parent")
        assert(termScopes.first(where: { $0.scope == .directory })?.isSupported == true, "Terminal should support directory")
        assert(termScopes.first(where: { $0.scope == .blankArea })?.isSupported == true, "Terminal should support blank area")
        print("     ✓ TerminalOpenAction scopes: PASSED")

        // 2c. File Manage Action (Cut & Paste & Delete)
        let cutAction = FileManageAction(type: .cut)
        let cutScopes = cutAction.targetScopeAvailabilities
        assert(cutScopes.first(where: { $0.scope == .singleFile })?.isSupported == true, "Cut should support single file")
        assert(cutScopes.first(where: { $0.scope == .multipleFiles })?.isSupported == true, "Cut should support multiple files")
        assert(cutScopes.first(where: { $0.scope == .blankArea })?.isSupported == false, "Cut should not support blank area")

        let pasteAction = FileManageAction(type: .paste)
        let pasteScopes = pasteAction.targetScopeAvailabilities
        assert(pasteScopes.first(where: { $0.scope == .singleFile })?.isSupported == false, "Paste should not support single file")
        assert(pasteScopes.first(where: { $0.scope == .directory })?.isSupported == true, "Paste should support directory")
        assert(pasteScopes.first(where: { $0.scope == .blankArea })?.isSupported == true, "Paste should support blank area")
        print("     ✓ FileManageAction scopes (Cut/Paste): PASSED")

        // 2d. Path Copy Action
        let pathCopyAction = PathCopyAction(kind: .shellEscaped)
        let pathCopyScopes = pathCopyAction.targetScopeAvailabilities
        assert(pathCopyScopes.first(where: { $0.scope == .singleFile })?.isSupported == true, "PathCopy should support single file")
        assert(pathCopyScopes.first(where: { $0.scope == .multipleFiles })?.isSupported == true, "PathCopy should support multiple files")
        assert(pathCopyScopes.first(where: { $0.scope == .blankArea })?.isSupported == false, "PathCopy should not support blank area")
        print("     ✓ PathCopyAction scopes: PASSED")

        // 2e. Utility Actions (MD5, Convert, QR, Hidden)
        let md5Action = UtilityAction(type: .calculateMD5)
        let md5Scopes = md5Action.targetScopeAvailabilities
        assert(md5Scopes.first(where: { $0.scope == .singleFile })?.isSupported == true, "MD5 should support single file")
        assert(md5Scopes.first(where: { $0.scope == .multipleFiles })?.isSupported == false, "MD5 should only support single file")
        assert(md5Scopes.first(where: { $0.scope == .directory })?.isSupported == false, "MD5 should not support directory")

        let convertAction = UtilityAction(type: .convertToPNG)
        let convertScopes = convertAction.targetScopeAvailabilities
        assert(convertScopes.first(where: { $0.scope == .singleFile })?.isSupported == true, "Convert should support single file")
        assert(convertScopes.first(where: { $0.scope == .multipleFiles })?.isSupported == true, "Convert should support multiple files")
        assert(convertScopes.first(where: { $0.scope == .directory })?.isSupported == false, "Convert should not support directory")

        let qrAction = UtilityAction(type: .textToQRCode)
        let qrScopes = qrAction.targetScopeAvailabilities
        assert(qrScopes.first(where: { $0.scope == .blankArea })?.isSupported == true, "QR should support blank area")

        let hiddenAction = UtilityAction(type: .toggleHiddenFiles)
        let hiddenScopes = hiddenAction.targetScopeAvailabilities
        assert(hiddenScopes.allSatisfy { $0.isSupported }, "Toggle hidden files should support all scopes")
        print("     ✓ UtilityAction scopes (MD5, Convert, QR, Hidden): PASSED")

        // MARK: 3. Selection & Staging Synchronization
        print("  -> Testing selection and staging synchronization...")
        coordinator.selectedActionId = nil
        assert(coordinator.selectedAction == nil, "selectedAction should be nil when selectedActionId is nil")

        coordinator.selectedActionId = newTxtAction.actionId
        assert(coordinator.selectedAction?.actionId == newTxtAction.actionId, "selectedAction should resolve newTxtAction")

        let isStagedBefore = coordinator.isActionStaged(actionId: newTxtAction.actionId)
        coordinator.toggleAction(actionId: newTxtAction.actionId)
        assert(coordinator.isActionStaged(actionId: newTxtAction.actionId) == !isStagedBefore, "Toggle should invert staging state")

        // Revert toggle
        coordinator.toggleAction(actionId: newTxtAction.actionId)
        assert(coordinator.isActionStaged(actionId: newTxtAction.actionId) == isStagedBefore, "Revert toggle should restore state")
        print("     ✓ Selection & Staging synchronization: PASSED")

        // MARK: 4. Action Parameters & Security Metadata
        print("  -> Testing action parameters and security metadata...")
        let deleteAction = FileManageAction(type: .permanentDelete)
        assert(deleteAction.isHighRisk == true, "Delete action should be marked high risk")
        assert(deleteAction.riskDescription != nil, "Delete action must have risk description")
        assert(deleteAction.tier == .advanced, "Delete action tier must be advanced")

        let vscodeAction = TerminalOpenAction(type: .vscode)
        assert(vscodeAction.associatedBundleIdentifier == "com.microsoft.VSCode", "VSCode bundle id must match")
        assert(vscodeAction.tier == .professional, "VSCode tier should be professional")
        print("     ✓ Action parameters & risk metadata: PASSED")

        // MARK: 5. SwiftUI Views Instantiation & Rendering
        print("  -> Testing SwiftUI Views Instantiation (Empty & Selected States)...")

        // 5a. Empty Inspector View
        coordinator.selectedActionId = nil
        let emptyInspector = ActionInspectorView(coordinator: coordinator)
        _ = emptyInspector.body

        let defaultInitInspector = ActionInspectorView()
        _ = defaultInitInspector.body

        // 5b. Inspector with each Category
        let testActionTypes: [MenuAction] = [
            NewFileAction(fileType: .docx),
            TerminalOpenAction(type: .iterm2),
            FileManageAction(type: .permanentDelete),
            PathCopyAction(kind: .gitRelative),
            UtilityAction(type: .calculateSHA256),
            UtilityAction(type: .textToQRCode),
            UtilityAction(type: .convertToJPEG)
        ]

        for action in testActionTypes {
            coordinator.selectedActionId = action.actionId
            let populatedInspector = ActionInspectorView(coordinator: coordinator)
            _ = populatedInspector.body
        }
        print("     ✓ Populated ActionInspectorView for all action categories: PASSED")

        // 5c. Multi-pane CanvasMainView & MainWindowView
        let canvasMainView = CanvasMainView(coordinator: coordinator)
        _ = canvasMainView.body

        let defaultCanvasMain = CanvasMainView()
        _ = defaultCanvasMain.body

        let mainWindow = MainWindowView(coordinator: coordinator, initialSection: .canvas)
        _ = mainWindow.body
        print("     ✓ CanvasMainView & MainWindowView integration: PASSED")

        print("🎉 ALL CONTEXTUAL ACTION INSPECTOR PANEL TESTS PASSED SUCCESSFULLY!")
    }
}
