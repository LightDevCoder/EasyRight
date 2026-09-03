import SwiftUI
import AppKit

@main
struct LanguageAndPresetTests {
    @MainActor
    static func main() async {
        print("🧪 [Test] Running Language & Preset Tests...")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storage = SharedStorageManager(sharedContainerURLOverride: tempDir)

        // MARK: 1. Language Switching & L10n Tests
        print("  -> Testing LanguageManager & L10n translations...")
        let langManager = AppLanguageManager.shared

        // Set to English
        langManager.language = .en
        assert(langManager.isEnglish == true, "LanguageManager should report isEnglish == true")
        assert(L10n.isEnglish == true, "L10n.isEnglish should be true")
        assert(L10n.tr("中文", "English") == "English", "L10n.tr should return English string")

        // Test action localized titles in English
        let newFileTxt = NewFileAction(fileType: .txt)
        assert(newFileTxt.localizedTitle == "New Plain Text (.txt)", "TXT action title should be in English")

        let cutAction = FileManageAction(type: .cut)
        assert(cutAction.localizedTitle == "Cut", "Cut action title should be in English")

        let terminalAction = TerminalOpenAction(type: .terminal)
        assert(terminalAction.localizedTitle == "Open in Terminal", "Terminal action title should be in English")

        let hashAction = UtilityAction(type: .calculateMD5)
        assert(hashAction.localizedTitle == "Calculate MD5 Checksum", "MD5 action title should be in English")

        // Test presets in English
        assert(StarterPreset.minimalist.title == "Minimalist", "Preset title should be Minimalist")
        assert(StarterPreset.developer.title == "Developer", "Preset title should be Developer")
        assert(StarterPreset.powerUser.title == "Power User", "Preset title should be Power User")

        // Switch to Simplified Chinese
        langManager.language = .zhHans
        assert(langManager.isEnglish == false, "LanguageManager should report isEnglish == false")
        assert(L10n.isEnglish == false, "L10n.isEnglish should be false")
        assert(L10n.tr("中文", "English") == "中文", "L10n.tr should return Chinese string")

        assert(newFileTxt.localizedTitle == "新建 文本文件 (.txt)", "TXT action title should be in Chinese")
        assert(cutAction.localizedTitle == "剪切", "Cut action title should be in Chinese")
        assert(terminalAction.localizedTitle == "在 系统终端 (Terminal) 中打开", "Terminal action title should be in Chinese")
        assert(hashAction.localizedTitle == "获取文件 MD5 校验码", "MD5 action title should be in Chinese")

        assert(StarterPreset.minimalist.title == "极简日常", "Preset title should be 极简日常")
        assert(StarterPreset.developer.title == "开发者特供", "Preset title should be 开发者特供")
        assert(StarterPreset.powerUser.title == "全能全景", "Preset title should be 全能全景")
        print("     ✓ LanguageManager & L10n translations: PASSED")

        // MARK: 2. Preset Application via Coordinator
        print("  -> Testing Coordinator applyPreset...")
        let coordinator = AppMenuStateCoordinator(storage: storage)

        // Apply Minimalist preset
        coordinator.applyPreset(.minimalist)
        assert(coordinator.canvasItems.count == StarterPreset.minimalist.canvasItems().count, "Canvas count should match Minimalist preset count")
        assert(coordinator.activePresetBadgeName == "Mini", "Minimalist preset badge must be Mini")
        let loadedItemsMin = storage.getCanvasItems()
        assert(loadedItemsMin?.count == coordinator.canvasItems.count, "Storage items must match applied Minimalist preset")

        // Apply Developer preset
        coordinator.applyPreset(.developer)
        assert(coordinator.canvasItems.count == StarterPreset.developer.canvasItems().count, "Canvas count should match Developer preset count")
        assert(coordinator.activePresetBadgeName == "Dev", "Developer preset badge must be Dev")
        let loadedItemsDev = storage.getCanvasItems()
        assert(loadedItemsDev?.count == coordinator.canvasItems.count, "Storage items must match applied Developer preset")

        // Apply Power User preset
        coordinator.applyPreset(.powerUser)
        assert(coordinator.canvasItems.count == StarterPreset.powerUser.canvasItems().count, "Canvas count should match Power User preset count")
        assert(coordinator.activePresetBadgeName == "Max", "Power User preset badge must be Max")
        let loadedItemsPower = storage.getCanvasItems()
        assert(loadedItemsPower?.count == coordinator.canvasItems.count, "Storage items must match applied Power User preset")

        // Modify canvas manually -> should become User
        coordinator.addSeparator()
        assert(coordinator.activePresetBadgeName == "User", "Modified canvas badge must be User")
        print("     ✓ Coordinator applyPreset & badge (Mini/Dev/Max/User): PASSED")

        // MARK: 3. PresetSelectionSheet Instantiation
        print("  -> Testing PresetSelectionSheet UI instantiation...")
        var isPresented = true
        let sheet = PresetSelectionSheet(
            coordinator: coordinator,
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 })
        )
        _ = sheet.body
        print("     ✓ PresetSelectionSheet UI instantiation: PASSED")

        print("🎉 ALL LANGUAGE & PRESET TESTS PASSED SUCCESSFULLY!")
    }
}
