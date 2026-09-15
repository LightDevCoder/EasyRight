import XCTest
@testable import EasyRightCore

final class ConfigBackupRecoveryTests: XCTestCase {

    private var manager: SharedStorageManager!
    private var rootURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let storage = try TestStorage.make()
        addTeardownBlock {
            try TestStorage.removeIfPresent(storage.root)
        }
        manager = storage.manager
        rootURL = storage.root
    }

    func testMirrorBackupCreatedOnConfigSave() throws {
        let testKey = "enable_action_test_mirror"
        manager.setBool(true, forKey: testKey)

        let backupConfigURL = manager.durableBackupDirectoryURL.appendingPathComponent("config.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupConfigURL.path))

        let data = try Data(contentsOf: backupConfigURL)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        XCTAssertEqual(json?[testKey] as? Bool, true)
    }

    func testMirrorBackupCreatedOnCanvasAndCustomAppSave() throws {
        let canvasItem = MenuCanvasItem.action(actionId: "test.action")
        let customApp = CustomAppAction(name: "TestApp", bundleIdentifier: "com.test.app", appPath: "/Applications/Test.app")

        XCTAssertTrue(manager.saveCanvasItems([canvasItem], postNotification: false))
        XCTAssertTrue(manager.saveCustomAppActions([customApp], postNotification: false))

        let backupActionConfigURL = manager.durableBackupDirectoryURL.appendingPathComponent("action_config.json")
        let backupCustomAppURL = manager.durableBackupDirectoryURL.appendingPathComponent("custom_app_actions.json")

        XCTAssertTrue(FileManager.default.fileExists(atPath: backupActionConfigURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupCustomAppURL.path))
    }

    func testAutoRestoreWhenPrimaryContainerMissing() throws {
        // 1. 设置并保存配置
        manager.setBool(true, forKey: "enable_action_restore_test")
        let canvasItem = MenuCanvasItem.action(actionId: "restore.canvas")
        let customApp = CustomAppAction(name: "RestoreApp", bundleIdentifier: "com.restore.app", appPath: "/Applications/Restore.app")
        XCTAssertTrue(manager.saveCanvasItems([canvasItem], postNotification: false))
        XCTAssertTrue(manager.saveCustomAppActions([customApp], postNotification: false))

        // 2. 模拟重装/扩展沙盒被清理：删除主容器内的所有配置文件
        try FileManager.default.removeItem(at: manager.configURL)
        try FileManager.default.removeItem(at: manager.actionConfigURL)
        try FileManager.default.removeItem(at: manager.customAppActionsURL)

        XCTAssertFalse(FileManager.default.fileExists(atPath: manager.configURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: manager.actionConfigURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: manager.customAppActionsURL.path))

        // 3. 执行启动期自愈检查
        let restored = manager.checkAndRestoreBackupIfNeeded()
        XCTAssertTrue(restored)

        // 4. 断言主容器文件已被完整还原
        XCTAssertTrue(FileManager.default.fileExists(atPath: manager.configURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: manager.actionConfigURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: manager.customAppActionsURL.path))

        // 5. 验证数据内容完全正确
        XCTAssertTrue(manager.getBool(forKey: "enable_action_restore_test"))
        let items = manager.getCanvasItems()
        XCTAssertEqual(items?.first?.actionId, "restore.canvas")
        let customApps = manager.getCustomAppActions()
        XCTAssertEqual(customApps.first?.bundleIdentifier, "com.restore.app")
    }

    func testExistingUserInitialBackupBackfill() throws {
        // 1. 模拟老用户状态：直接在主容器写入 config.json，而备份目录为空
        let legacyData = try JSONSerialization.data(withJSONObject: ["legacy_key": true], options: .prettyPrinted)
        try legacyData.write(to: manager.configURL, options: .atomic)

        let backupConfigURL = manager.durableBackupDirectoryURL.appendingPathComponent("config.json")
        try? FileManager.default.removeItem(at: backupConfigURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: backupConfigURL.path))

        // 2. 执行自愈检查
        let restored = manager.checkAndRestoreBackupIfNeeded()
        XCTAssertFalse(restored)

        // 3. 断言备份已自动补录
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupConfigURL.path))
        let backedUpData = try Data(contentsOf: backupConfigURL)
        let json = try JSONSerialization.jsonObject(with: backedUpData, options: []) as? [String: Any]
        XCTAssertEqual(json?["legacy_key"] as? Bool, true)
    }

    func testCorruptBackupNotRestored() throws {
        // 1. 写入损坏的备份数据
        let corruptData = "not valid json {[[".data(using: .utf8)!
        let backupConfigURL = manager.durableBackupDirectoryURL.appendingPathComponent("config.json")
        try corruptData.write(to: backupConfigURL, options: .atomic)

        // 2. 确保主容器文件不存在
        try? FileManager.default.removeItem(at: manager.configURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: manager.configURL.path))

        // 3. 自愈检查应拒绝恢复
        let restored = manager.checkAndRestoreBackupIfNeeded()
        XCTAssertFalse(restored)
        XCTAssertFalse(FileManager.default.fileExists(atPath: manager.configURL.path))
    }
}
