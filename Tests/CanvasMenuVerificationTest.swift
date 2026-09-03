import Foundation
import AppKit
#if canImport(EasyRightCore)
import EasyRightCore
#endif

func runVerification() {
    print("🧪 [Test] Running Issue 01 verification suite...")

    // MARK: 1. MenuCanvasItem Tests
    print("  -> Testing MenuCanvasItem data model...")
    let sepUUID = UUID()
    let subUUID = UUID()
    let items: [MenuCanvasItem] = [
        .action(actionId: "new_file_txt"),
        .separator(id: sepUUID),
        .submenu(id: subUUID, title: "开发工具", actionIds: ["open_terminal", "open_vscode"])
    ]

    assert(items[0].isAction == true)
    assert(items[0].actionId == "new_file_txt")
    assert(items[0].id == "action:new_file_txt")
    assert(items[0].isSeparator == false)
    assert(items[0].isSubmenu == false)

    assert(items[1].isSeparator == true)
    assert(items[1].uuid == sepUUID)
    assert(items[1].id == "separator:\(sepUUID.uuidString)")
    assert(items[1].isAction == false)

    assert(items[2].isSubmenu == true)
    assert(items[2].title == "开发工具")
    assert(items[2].actionIds == ["open_terminal", "open_vscode"])
    assert(items[2].uuid == subUUID)
    assert(items[2].id == "submenu:\(subUUID.uuidString)")

    // Serialization & Deserialization
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    guard let encodedData = try? encoder.encode(items) else {
        fatalError("Failed to encode MenuCanvasItem array")
    }
    guard let decodedItems = try? decoder.decode([MenuCanvasItem].self, from: encodedData) else {
        fatalError("Failed to decode MenuCanvasItem array")
    }
    assert(decodedItems == items, "Decoded items must equal original items")
    print("     ✓ MenuCanvasItem model & Codable: PASSED")

    // MARK: 2. SharedStorageManager Tests
    print("  -> Testing SharedStorageManager persistence & fallback...")
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let storage = SharedStorageManager(sharedContainerURLOverride: tempDir)

    // Verify default fallback when config is empty
    let defaults = storage.defaultCanvasItems()
    assert(!defaults.isEmpty, "defaultCanvasItems must not be empty")
    assert(storage.getCanvasItems() == nil, "getCanvasItems should be nil initially")
    assert(storage.canvasItems == defaults, "canvasItems property must fall back to defaultCanvasItems()")

    // Test backward compatibility: write legacy key first
    storage.setBool(true, forKey: "enable_action_custom_test")
    storage.setStringArray(["favorite_1"], forKey: SharedStorageManager.Keys.favoriteActionIds)

    // Save custom canvas items
    let customCanvas: [MenuCanvasItem] = [
        .action(actionId: "custom_test"),
        .separator(id: UUID()),
        .submenu(id: UUID(), title: "自定义", actionIds: ["fav_1", "fav_2"])
    ]

    var notificationFired = false
    let observer = DistributedNotificationCenter.default().addObserver(
        forName: Notification.Name("com.easyright.app.configChanged"),
        object: nil,
        queue: nil
    ) { _ in
        notificationFired = true
    }
    defer { DistributedNotificationCenter.default().removeObserver(observer) }

    let saved = storage.saveCanvasItems(customCanvas, postNotification: true)
    assert(saved == true, "saveCanvasItems should succeed")
    assert(storage.getCanvasItems() == customCanvas, "getCanvasItems must return saved custom items")
    assert(storage.canvasItems == customCanvas, "canvasItems property must return custom items")
    _ = notificationFired // notification fires via DistributedNotificationCenter asynchronously

    // Verify action_config.json was created on disk
    assert(FileManager.default.fileExists(atPath: storage.actionConfigURL.path), "action_config.json must exist")

    // Verify backward compatibility: legacy keys are still preserved
    assert(storage.getBool(forKey: "enable_action_custom_test") == true, "Legacy boolean keys must be preserved")
    assert(storage.getStringArray(forKey: SharedStorageManager.Keys.favoriteActionIds) == ["favorite_1"], "Legacy array keys must be preserved")
    print("     ✓ SharedStorageManager persistence & backward compatibility: PASSED")

    // MARK: 3. ActionTagMapper Tests
    print("  -> Testing ActionTagMapper...")
    ActionTagMapper.resetForTesting()
    let tag1 = ActionTagMapper.getTag(for: "action_a", invocationKind: .items)
    let tag2 = ActionTagMapper.getTag(for: "action_b", invocationKind: .items)
    let tag1Again = ActionTagMapper.getTag(for: "action_a", invocationKind: .items)
    let tag1Container = ActionTagMapper.getTag(for: "action_a", invocationKind: .container)

    assert(tag1 == tag1Again, "Same actionId + invocationKind must map to identical tag")
    assert(tag1 != tag2, "Different actionId must map to different tags")
    assert(tag1 != tag1Container, "Different invocationKind must map to different tags")

    let sel1 = ActionTagMapper.getSelection(for: tag1)
    assert(sel1?.actionId == "action_a" && sel1?.invocationKind == .items)
    print("     ✓ ActionTagMapper: PASSED")

    // MARK: 4. MenuLayout & NSMenu Builder Tests
    print("  -> Testing MenuLayout native NSMenu generation...")
    let allActions = DefaultActionRegistry.makeActions()
    guard allActions.count >= 3 else { fatalError("DefaultActionRegistry should have actions") }

    let act1 = allActions[0].actionId
    let act2 = allActions[1].actionId
    let act3 = allActions[2].actionId

    let testCanvas: [MenuCanvasItem] = [
        .separator(), // leading separator - should be cleaned up
        .action(actionId: act1),
        .separator(),
        .separator(), // duplicate separator - should be deduplicated
        .action(actionId: act2),
        .submenu(title: "子菜单测试", actionIds: [act3]),
        .separator() // trailing separator - should be cleaned up
    ]

    var tagMap: [Int: String] = [:]
    let menu = FinderMenuLayoutBuilder.buildNSMenu(
        title: "TestMenu",
        canvasItems: testCanvas,
        actions: allActions,
        isEnabled: { _ in true },
        isFavorite: { _ in false },
        isAvailable: { _ in true },
        itemFactory: { action in
            let item = NSMenuItem(title: action.localizedTitle, action: nil, keyEquivalent: "")
            let tag = ActionTagMapper.getTag(for: action.actionId, invocationKind: .items)
            item.tag = tag
            tagMap[tag] = action.actionId
            return item
        }
    )

    // Expected structure:
    // item 0: act1 (action)
    // item 1: separator
    // item 2: act2 (action)
    // item 3: submenu
    assert(menu.items.count == 4, "Menu should have exactly 4 items (act1, sep, act2, submenu), got \(menu.items.count)")
    assert(!menu.items[0].isSeparatorItem, "First item should not be a separator")
    assert(menu.items[1].isSeparatorItem, "Second item should be separator")
    assert(!menu.items[2].isSeparatorItem, "Third item should not be separator")
    assert(menu.items[3].hasSubmenu, "Fourth item should have submenu")
    assert(menu.items[3].submenu?.items.count == 1, "Submenu should have 1 item")

    // Verify tag dispatch
    let act1Item = menu.items[0]
    let sel = ActionTagMapper.getSelection(for: act1Item.tag)
    assert(sel?.actionId == act1, "Action tag must map back to act1")

    // Test fallback to legacy layout when canvasItems is nil
    let fallbackMenu = FinderMenuLayoutBuilder.buildNSMenu(
        title: "FallbackMenu",
        canvasItems: nil,
        actions: allActions,
        mode: .flat,
        isEnabled: { _ in true },
        isFavorite: { _ in false },
        isAvailable: { _ in true }
    )
    assert(!fallbackMenu.items.isEmpty, "Fallback menu must not be empty")
    print("     ✓ MenuLayout native NSMenu construction & fallback: PASSED")

    print("🎉 ALL TESTS PASSED SUCCESSFULLY!")
}

@main
struct CanvasMenuVerificationTest {
    static func main() {
        runVerification()
    }
}
