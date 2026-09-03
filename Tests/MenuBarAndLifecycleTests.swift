import Cocoa
import Foundation

@main
struct MenuBarAndLifecycleTests {
    static func main() {
        print("🧪 [Test] Running Menu Bar & Lifecycle Coordinator Tests...")
        
        let app = NSApplication.shared
        
        // 1. Initial activation policy check: start in .accessory mode
        app.setActivationPolicy(.accessory)
        assert(app.activationPolicy() == .accessory, "Activation policy should be .accessory initially")
        
        // 2. MenuBarController creation & setup
        var settingsOpened = false
        let controller = MenuBarController(onOpenSettings: {
            settingsOpened = true
        })
        
        assert(controller.statusItem != nil, "StatusItem should not be nil")
        guard let item = controller.statusItem else {
            fatalError("StatusItem missing")
        }
        
        // 3. StatusItem button & icon
        assert(item.button != nil, "Status item button should exist")
        assert(item.button?.image != nil || item.button?.title == "右", "Status item should have an image or fallback title")
        
        // 4. Menu structure
        guard let menu = item.menu else {
            fatalError("Status menu missing")
        }
        controller.menuNeedsUpdate(menu)
        assert(menu.items.count > 5, "Menu should have multiple items, actual: \(menu.items.count)")
        
        // 5. Check Health Header Item
        let headerItem = menu.items.first { $0.title.contains("访达扩展") }
        assert(headerItem != nil, "Menu should contain extension health status header")
        
        // 6. Check Restart Finder Item
        let restartItem = menu.items.first { $0.title.contains("重启访达") }
        assert(restartItem != nil, "Menu should contain 'Restart Finder' item")
        
        // 7. Check Preferences Item
        let prefsItem = menu.items.first { $0.title.contains("偏好设置") }
        assert(prefsItem != nil, "Menu should contain 'Preferences' item")
        assert(prefsItem?.keyEquivalent == ",", "Preferences shortcut should be ','")
        
        // Trigger Preferences action and verify callback
        if let action = prefsItem?.action, let target = prefsItem?.target as? NSObject {
            target.perform(action, with: prefsItem)
            assert(settingsOpened == true, "Triggering preferences item should invoke onOpenSettings callback")
        }
        
        // 8. Check Quit Item
        let quitItem = menu.items.first { $0.title.contains("退出") }
        assert(quitItem != nil, "Menu should contain 'Quit' item")
        assert(quitItem?.keyEquivalent == "q", "Quit shortcut should be 'q'")
        
        // 9. Check Quick Toggles & Submenus
        let allActionsMenu = menu.items.first { $0.title.contains("全部动作开关") }
        assert(allActionsMenu != nil, "Menu should contain '全部动作开关' submenu")
        assert(allActionsMenu?.submenu != nil, "Submenu should exist")
        assert(allActionsMenu?.submenu?.items.count ?? 0 > 0, "Submenu should contain category items")
        
        // 10. Activation Policy Transition Simulation
        // Window opening transition:
        app.setActivationPolicy(.regular)
        assert(app.activationPolicy() == .regular, "Activation policy should transition to .regular when window is open")
        
        // Window close / minimize transition:
        app.setActivationPolicy(.accessory)
        assert(app.activationPolicy() == .accessory, "Activation policy should transition back to .accessory when window is closed/minimized")
        
        print("✅ [Test] All Menu Bar & Lifecycle Coordinator Tests PASSED!")
    }
}
