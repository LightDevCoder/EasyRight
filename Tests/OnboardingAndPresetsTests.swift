import SwiftUI
import AppKit
import FinderSync

@main
struct OnboardingAndPresetsTests {
    @MainActor
    static func main() async {
        print("🧪 [Test] Running Issue 09 First-Run Onboarding & Presets Tests...")

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storage = SharedStorageManager(sharedContainerURLOverride: tempDir)
        let coordinator = AppMenuStateCoordinator(storage: storage)
        let allRegistryActions = DefaultActionRegistry.allActions
        let allActionIdSet = Set(allRegistryActions.map { $0.actionId })

        // MARK: 1. StarterPreset Enum & Model Verification
        print("  -> 1. Testing StarterPreset Enum & Canvas Item Models...")
        assert(StarterPreset.allCases.count == 3, "Must have 3 starter presets")

        for preset in StarterPreset.allCases {
            assert(!preset.id.isEmpty, "Preset ID must not be empty")
            assert(!preset.title.isEmpty, "Preset title must not be empty")
            assert(!preset.subtitle.isEmpty, "Preset subtitle must not be empty")
            assert(!preset.description.isEmpty, "Preset description must not be empty")
            assert(!preset.iconName.isEmpty, "Preset icon name must not be empty")
            assert(!preset.tag.isEmpty, "Preset tag must not be empty")
            assert(!preset.previewHighlights.isEmpty, "Preset preview highlights must not be empty")

            let items = preset.canvasItems()
            assert(!items.isEmpty, "Preset items must not be empty")
            assert(preset.actionCount == items.filter { $0.isAction }.count, "actionCount must match action items")
            assert(preset.separatorCount == items.filter { $0.isSeparator }.count, "separatorCount must match separators")

            // Verify all referenced action IDs exist in the system registry
            for item in items {
                if case .action(let actionId) = item {
                    assert(
                        allActionIdSet.contains(actionId),
                        "Preset \(preset.rawValue) contains unknown action ID: \(actionId)"
                    )
                }
            }
        }
        print("     ✓ All StarterPresets validated against Action Registry: PASSED")

        // MARK: 2. Specific Preset Content Verification
        print("  -> 2. Verifying Specific Preset Layouts...")

        // 2a. Minimalist
        let minItems = StarterPreset.minimalist.canvasItems()
        let minActionIds = minItems.compactMap { $0.actionId }
        assert(minActionIds.contains("easyright.action.newfile.txt"), "Minimalist should contain txt")
        assert(minActionIds.contains("easyright.action.newfile.docx"), "Minimalist should contain docx")
        assert(minActionIds.contains("easyright.action.filemanage.cut"), "Minimalist should contain cut")
        assert(minActionIds.contains("easyright.action.filemanage.copyPath"), "Minimalist should contain copyPath")
        assert(minActionIds.contains("easyright.action.terminal.terminal"), "Minimalist should contain terminal")
        assert(minItems.filter { $0.isSeparator }.count >= 2, "Minimalist should have separators")
        assert(StarterPreset.minimalist.actionCount == 5, "Minimalist must have 5 actions")
        print("     ✓ Minimalist preset verification: PASSED")

        // 2b. Developer
        let devItems = StarterPreset.developer.canvasItems()
        let devActionIds = devItems.compactMap { $0.actionId }
        assert(devActionIds.contains("easyright.action.terminal.terminal"), "Developer should contain terminal")
        assert(devActionIds.contains("easyright.action.terminal.vscode"), "Developer should contain vscode")
        assert(devActionIds.contains("easyright.action.pathcopy.shellEscaped"), "Developer should contain shellEscaped")
        assert(devActionIds.contains("easyright.action.pathcopy.gitRelative"), "Developer should contain gitRelative")
        assert(devActionIds.contains("easyright.action.filemanage.copyPath"), "Developer should contain copyPath")
        assert(devActionIds.contains("easyright.action.newfile.md"), "Developer should contain md")
        assert(devActionIds.contains("easyright.action.newfile.json"), "Developer should contain json")
        assert(devActionIds.contains("easyright.action.utility.calculateSHA256"), "Developer should contain SHA256")
        assert(devActionIds.contains("easyright.action.utility.calculateMD5"), "Developer should contain MD5")
        assert(devActionIds.contains("easyright.action.utility.toggleHiddenFiles"), "Developer should contain toggleHiddenFiles")
        assert(devItems.filter { $0.isSeparator }.count >= 3, "Developer should have at least 3 separators")
        print("     ✓ Developer preset verification: PASSED")

        // 2c. Power User
        let powerItems = StarterPreset.powerUser.canvasItems()
        let powerActionIds = powerItems.compactMap { $0.actionId }
        assert(powerActionIds.contains("easyright.action.newfile.txt"), "Power user should contain txt")
        assert(powerActionIds.contains("easyright.action.newfile.md"), "Power user should contain md")
        assert(powerActionIds.contains("easyright.action.newfile.docx"), "Power user should contain docx")
        assert(powerActionIds.contains("easyright.action.newfile.xlsx"), "Power user should contain xlsx")
        assert(powerActionIds.contains("easyright.action.filemanage.cut"), "Power user should contain cut")
        assert(powerActionIds.contains("easyright.action.filemanage.paste"), "Power user should contain paste")
        assert(powerActionIds.contains("easyright.action.terminal.terminal"), "Power user should contain terminal")
        assert(powerActionIds.contains("easyright.action.terminal.vscode"), "Power user should contain vscode")
        assert(powerActionIds.contains("easyright.action.utility.toggleHiddenFiles"), "Power user should contain toggleHiddenFiles")
        assert(powerActionIds.contains("easyright.action.utility.textToQRCode"), "Power user should contain textToQRCode")
        assert(powerActionIds.contains("easyright.action.utility.convertToPNG"), "Power user should contain convertToPNG")
        assert(powerItems.filter { $0.isSeparator }.count >= 3, "Power user should have at least 3 separators")
        print("     ✓ Power user preset verification: PASSED")

        // MARK: 3. Preset Application & Storage Persistence
        print("  -> 3. Testing Preset Application & Shared Storage Persistence...")
        for preset in StarterPreset.allCases {
            let items = preset.canvasItems()
            coordinator.canvasItems = items
            let saveSuccess = storage.saveCanvasItems(items, postNotification: false)
            assert(saveSuccess, "Saving preset \(preset.rawValue) must succeed")

            let loaded = storage.getCanvasItems()
            assert(loaded != nil, "Loaded items should not be nil")
            assert(loaded?.count == items.count, "Loaded item count should match preset count")
            assert(loaded == items, "Loaded items should match preset items exactly")
        }

        // Onboarding completion flag in SharedStorageManager
        assert(storage.hasCompletedOnboarding == false, "Initial hasCompletedOnboarding should be false")
        storage.hasCompletedOnboarding = true
        assert(storage.hasCompletedOnboarding == true, "hasCompletedOnboarding should persist as true")
        storage.hasCompletedOnboarding = false
        assert(storage.hasCompletedOnboarding == false, "hasCompletedOnboarding should be resettable")
        print("     ✓ Storage persistence & Onboarding flag: PASSED")

        // MARK: 4. OnboardingStep Model
        print("  -> 4. Testing OnboardingStep Model...")
        assert(OnboardingStep.allCases.count == 3, "Must have 3 onboarding steps")
        assert(OnboardingStep.welcome.rawValue == 0, "Welcome should be step 0")
        assert(OnboardingStep.permissions.rawValue == 1, "Permissions should be step 1")
        assert(OnboardingStep.preset.rawValue == 2, "Preset should be step 2")

        for step in OnboardingStep.allCases {
            assert(!step.stepTitle.isEmpty, "Step title must not be empty")
            assert(!step.stepSubtitle.isEmpty, "Step subtitle must not be empty")
            assert(!step.iconName.isEmpty, "Step icon must not be empty")
        }
        print("     ✓ OnboardingStep model: PASSED")

        // MARK: 5. Diagnostic Extension Status Checking
        print("  -> 5. Testing FinderExtensionDiagnostics.checkStatus()...")
        let status = FinderExtensionDiagnostics.checkStatus()
        assert(
            status == .enabled || status == .registeredButNotEnabled || status == .notRegistered || status == .unknown,
            "checkStatus must return a valid FinderExtensionRegistrationState"
        )
        print("     ✓ checkStatus() returned \(status): PASSED")

        // MARK: 6. OnboardingView SwiftUI Instantiation & Dismissal
        print("  -> 6. Testing OnboardingView View Instantiation...")
        var isPresented = true
        var completedCalled = false

        let onboardingView = OnboardingView(
            coordinator: coordinator,
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            onComplete: {
                completedCalled = true
            }
        )
        _ = onboardingView.body
        assert(completedCalled == false, "completedCalled should initially be false")
        print("     ✓ OnboardingView body evaluation: PASSED")

        // MARK: 7. MainWindowView Integration with Onboarding
        print("  -> 7. Testing MainWindowView Integration...")
        let mainWindowWithOnboarding = MainWindowView(
            coordinator: coordinator,
            initialSection: .canvas,
            showOnboarding: true
        )
        _ = mainWindowWithOnboarding.body

        let mainWindowDefault = MainWindowView(coordinator: coordinator, initialSection: .canvas)
        _ = mainWindowDefault.body

        // Verify Notification identifier
        assert(
            Notification.Name.showOnboarding.rawValue == "com.easyright.app.showOnboarding",
            "showOnboarding notification name must match expected identifier"
        )
        print("     ✓ MainWindowView & Notification integration: PASSED")

        print("🎉 ALL ONBOARDING AND STARTER PRESETS TESTS PASSED SUCCESSFULLY!")
    }
}
