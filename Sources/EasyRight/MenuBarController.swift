import Cocoa
import Foundation

/// Controls the macOS menu bar status item and dropdown menu for EasyRight.
/// Serves as the lightweight resident entry point in .accessory mode.
public final class MenuBarController: NSObject, NSMenuDelegate {
    
    public private(set) var statusItem: NSStatusItem?
    private let statusMenu = NSMenu(title: "开源EasyRight")
    private let onOpenSettings: () -> Void
    
    // Cached snapshot to avoid blocking main thread on rapid menu opens
    private var cachedSnapshot: RightClickMenuHealthSnapshot?
    private var lastSnapshotTime: TimeInterval = 0
    private let snapshotTTL: TimeInterval = 4.0
    
    // Quick toggle target action IDs
    private let primaryQuickActionIds: [String] = [
        "easyright.action.newfile.txt",
        "easyright.action.newfile.docx",
        "easyright.action.newfile.md",
        "easyright.action.filemanage.cut",
        "easyright.action.filemanage.copypath",
        "easyright.action.terminal.default",
        "easyright.action.utility.hiddenfiles",
        "easyright.action.utility.qrcode"
    ]
    
    public init(onOpenSettings: @escaping () -> Void) {
        self.onOpenSettings = onOpenSettings
        super.init()
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        
        // Use adaptive monochrome SF Symbol
        let symbolNames = ["cursorarrow.rays", "contextualmenu", "line.3.horizontal"]
        for name in symbolNames {
            if let image = NSImage(systemSymbolName: name, accessibilityDescription: "开源EasyRight") {
                image.isTemplate = true
                button.image = image
                break
            }
        }
        
        // Defensive fallback to prevent 0-width collapse
        if button.image == nil {
            button.title = "右"
        }
        button.toolTip = "开源EasyRight (EasyRight)"
        
        statusMenu.delegate = self
        rebuildMenu(statusMenu)
        statusItem?.menu = statusMenu
    }
    
    // MARK: - NSMenuDelegate
    
    public func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu(menu)
    }
    
    // MARK: - Menu Construction
    
    private func getHealthSnapshot() -> RightClickMenuHealthSnapshot {
        let now = Date().timeIntervalSince1970
        if let cached = cachedSnapshot, now - lastSnapshotTime < snapshotTTL {
            return cached
        }
        let snapshot = makeRightClickMenuHealthSnapshot()
        cachedSnapshot = snapshot
        lastSnapshotTime = now
        return snapshot
    }
    
    private func rebuildMenu(_ menu: NSMenu) {
        menu.removeAllItems()
        
        // 1. Extension Health Header
        let snapshot = getHealthSnapshot()
        let headerTitle: String
        let headerImageName: String
        
        switch snapshot.healthLevel {
        case .healthy:
            let count = snapshot.observedPathCount
            headerTitle = count > 0 ? "🟢 访达扩展：正常运行 (\(count)个路径)" : "🟢 访达扩展：正常运行"
            headerImageName = "checkmark.circle.fill"
        case .warning:
            headerTitle = "🟡 访达扩展：需要关注 (Warning)"
            headerImageName = "exclamationmark.triangle.fill"
        case .critical:
            headerTitle = "🔴 访达扩展：未启用或异常 (Disabled)"
            headerImageName = "xmark.octagon.fill"
        }
        
        let headerItem = NSMenuItem(title: headerTitle, action: #selector(handleStatusHeaderClicked), keyEquivalent: "")
        headerItem.target = self
        if let img = NSImage(systemSymbolName: headerImageName, accessibilityDescription: nil) {
            img.isTemplate = false
            headerItem.image = img
        }
        headerItem.toolTip = "点击打开系统诊断与偏好设置"
        menu.addItem(headerItem)
        
        if snapshot.healthLevel != .healthy {
            let repairItem = NSMenuItem(title: "   ↳ 查看诊断与一键修复…", action: #selector(handleStatusHeaderClicked), keyEquivalent: "")
            repairItem.target = self
            menu.addItem(repairItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. Quick Action Toggles
        let allActions = DefaultActionRegistry.makeActions()
        let actionMap = Dictionary(uniqueKeysWithValues: allActions.map { ($0.actionId, $0) })
        
        // Section title
        let sectionHeaderItem: NSMenuItem
        if #available(macOS 14.0, *) {
            sectionHeaderItem = NSMenuItem.sectionHeader(title: "常用功能快捷开关")
        } else {
            sectionHeaderItem = NSMenuItem(title: "—— 常用功能快捷开关 ——", action: nil, keyEquivalent: "")
            sectionHeaderItem.isEnabled = false
        }
        menu.addItem(sectionHeaderItem)
        
        // Primary toggles
        for actionId in primaryQuickActionIds {
            guard let action = actionMap[actionId] else { continue }
            let isEnabled = SharedStorageManager.shared.isActionEnabled(action)
            let item = NSMenuItem(
                title: action.localizedTitle,
                action: #selector(handleToggleQuickAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = action.actionId
            item.state = isEnabled ? .on : .off
            if let iconName = action.iconName, let img = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                img.isTemplate = true
                item.image = img
            }
            menu.addItem(item)
        }
        
        // Submenu: All Actions by Category
        let moreActionsMenu = NSMenu(title: "更多动作开关")
        for category in ActionCategory.allCases {
            let categoryActions = allActions.filter { $0.category == category }
            guard !categoryActions.isEmpty else { continue }
            
            let categorySubmenu = NSMenu(title: category.localizedName)
            for action in categoryActions {
                let isEnabled = SharedStorageManager.shared.isActionEnabled(action)
                let item = NSMenuItem(
                    title: action.localizedTitle,
                    action: #selector(handleToggleQuickAction(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = action.actionId
                item.state = isEnabled ? .on : .off
                if let iconName = action.iconName, let img = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                    img.isTemplate = true
                    item.image = img
                }
                categorySubmenu.addItem(item)
            }
            
            let categoryItem = NSMenuItem(title: category.localizedName, action: nil, keyEquivalent: "")
            categoryItem.submenu = categorySubmenu
            moreActionsMenu.addItem(categoryItem)
        }
        
        let moreActionsItem = NSMenuItem(title: "全部动作开关…", action: nil, keyEquivalent: "")
        moreActionsItem.submenu = moreActionsMenu
        menu.addItem(moreActionsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 3. Restart Finder
        let restartFinderItem = NSMenuItem(
            title: "重启访达 (Restart Finder)",
            action: #selector(handleRestartFinderClicked),
            keyEquivalent: ""
        )
        restartFinderItem.target = self
        if let restartImg = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "重启访达") {
            restartImg.isTemplate = true
            restartFinderItem.image = restartImg
        }
        menu.addItem(restartFinderItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Preferences / Studio Window
        let settingsItem = NSMenuItem(
            title: "偏好设置…",
            action: #selector(handleOpenSettingsClicked),
            keyEquivalent: ","
        )
        settingsItem.target = self
        if let settingsImg = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "偏好设置") {
            settingsImg.isTemplate = true
            settingsItem.image = settingsImg
        }
        menu.addItem(settingsItem)

        let onboardingItem = NSMenuItem(
            title: "重新运行新手引导…",
            action: #selector(handleRerunOnboardingClicked),
            keyEquivalent: ""
        )
        onboardingItem.target = self
        if let onboardingImg = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "重新运行新手引导") {
            onboardingImg.isTemplate = true
            onboardingItem.image = onboardingImg
        }
        menu.addItem(onboardingItem)
        
        // 5. Silent Launch
        let silentLaunchItem = NSMenuItem(
            title: "静默启动",
            action: #selector(handleToggleSilentLaunch(_:)),
            keyEquivalent: ""
        )
        silentLaunchItem.target = self
        silentLaunchItem.state = isSilentLaunchEnabled ? .on : .off
        menu.addItem(silentLaunchItem)
        
        // 6. About
        let aboutItem = NSMenuItem(
            title: "关于EasyRight",
            action: #selector(handleShowAboutDialog),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 7. Quit
        let quitItem = NSMenuItem(
            title: "退出EasyRight",
            action: #selector(handleQuitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func handleStatusHeaderClicked() {
        onOpenSettings()
    }
    
    @objc private func handleOpenSettingsClicked() {
        onOpenSettings()
    }

    @objc private func handleRerunOnboardingClicked() {
        onOpenSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NotificationCenter.default.post(name: .showOnboarding, object: nil)
        }
    }
    
    @objc private func handleToggleQuickAction(_ sender: NSMenuItem) {
        guard let actionId = sender.representedObject as? String else { return }
        let key = "enable_action_\(actionId)"
        let currentState = sender.state == .on
        let newState = !currentState
        
        let success = SharedStorageManager.shared.setBool(newState, forKey: key)
        if success {
            ActionConfigCache.shared.invalidate()
            SystemReloader.postConfigChanged()
            sender.state = newState ? .on : .off
            
            SharedHUDManager.show(
                title: newState ? "已启用动作" : "已禁用动作",
                content: sender.title,
                iconName: newState ? "checkmark.circle" : "slash.circle",
                isSuccess: true
            )
        } else {
            SharedHUDManager.show(
                title: "设置保存失败",
                content: "无法写入配置，请检查权限",
                isSuccess: false
            )
        }
    }
    
    @objc private func handleRestartFinderClicked() {
        SharedHUDManager.show(
            title: "正在重启 Finder",
            content: "已发送重启指令，正在让 Finder 按新配置加载右键菜单…",
            iconName: "arrow.clockwise",
            isSuccess: true
        )
        SystemReloader.postConfigChanged()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = SystemReloader.restartFinder()
            DispatchQueue.main.async { [weak self] in
                self?.cachedSnapshot = nil // Invalidate health cache
                if !result.isSuccess {
                    SharedHUDManager.show(
                        title: "Finder 重启失败",
                        content: result.errorDescription ?? "请手动在终端运行 killall Finder",
                        iconName: "exclamationmark.triangle",
                        isSuccess: false
                    )
                }
            }
        }
    }
    
    private var isSilentLaunchEnabled: Bool {
        SharedStorageManager.shared.getBool(
            forKey: LaunchPresentationPolicy.silentLaunchKey,
            defaultValue: true
        )
    }
    
    @objc private func handleToggleSilentLaunch(_ sender: NSMenuItem) {
        let newValue = !isSilentLaunchEnabled
        guard SharedStorageManager.shared.setBool(
            newValue,
            forKey: LaunchPresentationPolicy.silentLaunchKey
        ) else {
            sender.state = isSilentLaunchEnabled ? .on : .off
            SharedHUDManager.show(
                title: "设置保存失败",
                content: "无法写入静默启动设置，请检查共享目录权限后重试。",
                isSuccess: false
            )
            return
        }
        sender.state = newValue ? .on : .off
        SharedHUDManager.show(
            title: newValue ? "静默启动已启用" : "静默启动已关闭",
            content: newValue ? "后台拉起时仅保留菜单栏图标" : "下次启动会直接显示设置窗口",
            iconName: newValue ? "moon.fill" : "macwindow",
            isSuccess: true
        )
    }
    
    @objc private func handleShowAboutDialog() {
        let alert = NSAlert()
        alert.messageText = "关于EasyRight"
        
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        alert.informativeText = """
        开源EasyRight (EasyRight)
        版本: v\(version)
        
        一款免费开源的 macOS 右键菜单增强工具。
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        
        alert.window.level = .modalPanel
        alert.window.orderFrontRegardless()
        alert.runModal()
    }
    
    @objc private func handleQuitClicked() {
        NSApp.terminate(nil)
    }
}
