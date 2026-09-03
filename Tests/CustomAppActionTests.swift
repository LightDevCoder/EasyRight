import Foundation
import AppKit
#if canImport(EasyRightCore)
import EasyRightCore
#endif

public func runCustomAppActionVerification() {
    print("🧪 [Test] Running CustomAppAction verification suite...")

    // 1. Target Filter Logic
    print("  -> 1. Testing CustomAppTargetFilter logic...")
    let filterAll = CustomAppTargetFilter.all
    assert(filterAll.displayName == "全部文件与文件夹")

    let filterDir = CustomAppTargetFilter.directoriesOnly
    assert(filterDir.displayName == "仅文件夹")

    let filterExt = CustomAppTargetFilter.extensions(["zip", "7z", "RAR"])
    assert(filterExt.displayName.contains("zip"))

    // 2. CustomAppAction Model & Codable
    print("  -> 2. Testing CustomAppAction Model & Serialization...")
    let testAction = CustomAppAction(
        name: "使用 Keka 压缩/解压",
        bundleIdentifier: "com.aone.keka",
        appPath: "/Applications/Keka.app",
        targetFilter: .extensions(["zip", "7z", "rar", "tar", "gz"]),
        isEnabled: true
    )

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    guard let data = try? encoder.encode(testAction),
          let decoded = try? decoder.decode(CustomAppAction.self, from: data) else {
        fatalError("Failed to encode/decode CustomAppAction")
    }

    assert(decoded.id == testAction.id)
    assert(decoded.name == testAction.name)
    assert(decoded.bundleIdentifier == "com.aone.keka")
    assert(decoded.targetFilter == testAction.targetFilter)
    assert(decoded.isEnabled == true)
    print("     ✓ CustomAppAction Model & Codable: PASSED")

    // 3. SharedStorageManager Persistence
    print("  -> 3. Testing SharedStorageManager persistence for CustomAppActions...")
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let storage = SharedStorageManager(sharedContainerURLOverride: tempDir)
    assert(storage.getCustomAppActions().isEmpty, "Initial custom app actions must be empty")

    let success = storage.saveCustomAppActions([testAction], postNotification: false)
    assert(success, "saveCustomAppActions must return true")

    let loaded = storage.getCustomAppActions()
    assert(loaded.count == 1, "Must load exactly 1 custom app action")
    assert(loaded.first?.bundleIdentifier == "com.aone.keka")
    print("     ✓ SharedStorageManager persistence: PASSED")

    // 4. CustomAppOpenAction MenuAction Compliance
    print("  -> 4. Testing CustomAppOpenAction MenuAction compliance...")
    let menuAction = CustomAppOpenAction(customApp: testAction)
    assert(menuAction.actionId == "easyright.action.customapp.\(testAction.id.uuidString)")
    assert(menuAction.localizedTitle == "使用 Keka 压缩/解压")
    assert(menuAction.category == .terminal)
    assert(menuAction.tier == .professional)
    assert(menuAction.associatedBundleIdentifier == "com.aone.keka")

    // Availability checks with target file extension matching
    let zipFile = URL(fileURLWithPath: "/tmp/sample_archive.zip")
    let txtFile = URL(fileURLWithPath: "/tmp/sample_document.txt")

    // Prepare temp files
    FileManager.default.createFile(atPath: zipFile.path, contents: Data())
    FileManager.default.createFile(atPath: txtFile.path, contents: Data())
    defer {
        try? FileManager.default.removeItem(at: zipFile)
        try? FileManager.default.removeItem(at: txtFile)
    }

    assert(menuAction.isAvailable(for: [zipFile]) == true, "Archive file .zip must match filter")
    assert(menuAction.isAvailable(for: [txtFile]) == false, "Document file .txt must NOT match filter")
    print("     ✓ CustomAppOpenAction availability & extension filtering: PASSED")

    // 5. Built-in 30 Actions Count Invariance
    print("  -> 5. Verifying DefaultActionRegistry invariants...")
    let builtinActions = DefaultActionRegistry.makeActions()
    assert(builtinActions.count == 30, "makeActions() MUST strictly maintain exactly 30 built-in actions")

    let allActions = DefaultActionRegistry.makeAllActions(storage: storage)
    assert(allActions.count == 31, "makeAllActions() must include 30 built-in + 1 custom action")
    assert(allActions.contains { $0.actionId == menuAction.actionId })
    print("     ✓ DefaultActionRegistry 30 built-in actions preserved & custom appended: PASSED")

    print("🎉 [Test] All CustomAppAction verification tests PASSED!")
}
