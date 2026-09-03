import AppKit
import Foundation

/// Finder 右键菜单展示模式。
/// - flat: 已启用且当前可用的动作直接显示在一级菜单中，收藏置顶。
/// - grouped: 兼容旧版，按动作分类放入二级子菜单。
public enum MenuLayoutMode: String, Codable, CaseIterable, Equatable, Identifiable {
    case flat
    case grouped

    public var id: String { rawValue }

    public var localizedName: String {
        switch self {
        case .flat: return "直接显示"
        case .grouped: return "分类显示"
        }
    }
}

/// FinderSync 渲染前的菜单布局计划。
/// 这里刻意只保留 actionId 和标题，便于单测和与平台解耦。
public enum FinderMenuLayoutSection: Equatable {
    case directItems(actionIds: [String])
    case submenu(title: String, actionIds: [String])
    case separator
}

/// 把动作集合与用户配置转换成菜单布局结构。
public enum FinderMenuLayoutBuilder {
    /// 基于模式的传统分组/平铺布局构建。
    public static func build(
        actions: [MenuAction],
        mode: MenuLayoutMode,
        isEnabled: (MenuAction) -> Bool,
        isFavorite: (MenuAction) -> Bool,
        isAvailable: (MenuAction) -> Bool
    ) -> [FinderMenuLayoutSection] {
        let eligible = actions.filter { action in
            isEnabled(action) && isAvailable(action)
        }

        switch mode {
        case .flat:
            return buildFlatSections(
                actions: eligible,
                isFavorite: isFavorite
            )
        case .grouped:
            return buildGroupedSections(
                actions: eligible,
                isFavorite: isFavorite
            )
        }
    }

    /// 基于画布项目序列构建抽象布局计划，支持单个动作、原生分隔线与子菜单。
    /// 若 canvasItems 为 nil 或空，自动回退到基于 mode 的传统布局。
    public static func buildSections(
        canvasItems: [MenuCanvasItem]?,
        actions: [MenuAction],
        mode: MenuLayoutMode = .flat,
        isEnabled: (MenuAction) -> Bool,
        isFavorite: (MenuAction) -> Bool,
        isAvailable: (MenuAction) -> Bool
    ) -> [FinderMenuLayoutSection] {
        guard let canvasItems = canvasItems, !canvasItems.isEmpty else {
            return build(
                actions: actions,
                mode: mode,
                isEnabled: isEnabled,
                isFavorite: isFavorite,
                isAvailable: isAvailable
            )
        }

        let actionMap = Dictionary(actions.map { ($0.actionId, $0) }, uniquingKeysWith: { first, _ in first })

        func isEligible(_ actionId: String) -> Bool {
            guard let action = actionMap[actionId] else { return false }
            return isEnabled(action) && isAvailable(action)
        }

        var sections: [FinderMenuLayoutSection] = []
        var pendingActionIds: [String] = []

        func flushPendingActions() {
            if !pendingActionIds.isEmpty {
                sections.append(.directItems(actionIds: pendingActionIds))
                pendingActionIds.removeAll()
            }
        }

        for item in canvasItems {
            switch item {
            case .action(let actionId):
                if isEligible(actionId) {
                    pendingActionIds.append(actionId)
                }
            case .separator:
                flushPendingActions()
                if let last = sections.last, last != .separator {
                    sections.append(.separator)
                }
            case .submenu(_, let title, let actionIds):
                flushPendingActions()
                let eligibleIds = actionIds.filter(isEligible)
                if !eligibleIds.isEmpty {
                    sections.append(.submenu(title: title, actionIds: eligibleIds))
                }
            }
        }
        flushPendingActions()

        if sections.last == .separator {
            sections.removeLast()
        }

        return sections
    }

    // MARK: - Native AppKit Menu Construction

    /// 为指定 MenuAction 创建默认的 NSMenuItem
    public static func defaultMenuItem(for action: MenuAction) -> NSMenuItem {
        let item = NSMenuItem(title: action.localizedTitle, action: nil, keyEquivalent: "")
        if let iconName = action.iconName {
            item.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        }
        return item
    }

    /// 解析 `[MenuCanvasItem]` 序列并构建原生 `[NSMenuItem]` 列表。
    /// - 若 `canvasItems` 为 nil 或空，回退至 flat/grouped 菜单布局。
    /// - 支持 `.action`、`.separator` 与 `.submenu` 递归生成子菜单。
    /// - 自动处理前后多余分隔符与连续分隔符。
    public static func buildMenuItems(
        canvasItems: [MenuCanvasItem]?,
        actions: [MenuAction],
        mode: MenuLayoutMode = .flat,
        isEnabled: (MenuAction) -> Bool,
        isFavorite: (MenuAction) -> Bool,
        isAvailable: (MenuAction) -> Bool,
        itemFactory: ((MenuAction) -> NSMenuItem)? = nil
    ) -> [NSMenuItem] {
        let makeItem = itemFactory ?? { defaultMenuItem(for: $0) }
        let actionMap = Dictionary(actions.map { ($0.actionId, $0) }, uniquingKeysWith: { first, _ in first })

        func isEligible(_ action: MenuAction) -> Bool {
            isEnabled(action) && isAvailable(action)
        }

        var result: [NSMenuItem] = []

        func appendSeparator() {
            guard let last = result.last, !last.isSeparatorItem else { return }
            result.append(.separator())
        }

        func cleanTrailingSeparator() {
            if let last = result.last, last.isSeparatorItem {
                result.removeLast()
            }
        }

        guard let canvasItems = canvasItems, !canvasItems.isEmpty else {
            let sections = build(
                actions: actions,
                mode: mode,
                isEnabled: isEnabled,
                isFavorite: isFavorite,
                isAvailable: isAvailable
            )
            for section in sections {
                switch section {
                case .directItems(let actionIds):
                    for actionId in actionIds {
                        guard let action = actionMap[actionId] else { continue }
                        result.append(makeItem(action))
                    }
                case .submenu(let title, let actionIds):
                    let subMenu = NSMenu(title: title)
                    for actionId in actionIds {
                        guard let action = actionMap[actionId] else { continue }
                        subMenu.addItem(makeItem(action))
                    }
                    if !subMenu.items.isEmpty {
                        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                        parent.submenu = subMenu
                        result.append(parent)
                    }
                case .separator:
                    appendSeparator()
                }
            }
            cleanTrailingSeparator()
            return result
        }

        for item in canvasItems {
            switch item {
            case .action(let actionId):
                guard let action = actionMap[actionId], isEligible(action) else { continue }
                result.append(makeItem(action))

            case .separator:
                appendSeparator()

            case .submenu(_, let title, let actionIds):
                let subMenu = NSMenu(title: title)
                for actionId in actionIds {
                    guard let action = actionMap[actionId], isEligible(action) else { continue }
                    subMenu.addItem(makeItem(action))
                }
                if !subMenu.items.isEmpty {
                    let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                    parent.submenu = subMenu
                    result.append(parent)
                }
            }
        }

        cleanTrailingSeparator()
        return result
    }

    /// 解析 `[MenuCanvasItem]` 序列并构建原生 `NSMenu` 菜单。
    public static func buildNSMenu(
        title: String = "开源EasyRight",
        canvasItems: [MenuCanvasItem]?,
        actions: [MenuAction],
        mode: MenuLayoutMode = .flat,
        isEnabled: (MenuAction) -> Bool,
        isFavorite: (MenuAction) -> Bool,
        isAvailable: (MenuAction) -> Bool,
        itemFactory: ((MenuAction) -> NSMenuItem)? = nil
    ) -> NSMenu {
        let menu = NSMenu(title: title)
        let items = buildMenuItems(
            canvasItems: canvasItems,
            actions: actions,
            mode: mode,
            isEnabled: isEnabled,
            isFavorite: isFavorite,
            isAvailable: isAvailable,
            itemFactory: itemFactory
        )
        for item in items {
            menu.addItem(item)
        }
        return menu
    }

    // MARK: - Private Legacy Layout Helpers

    private static func buildFlatSections(
        actions: [MenuAction],
        isFavorite: (MenuAction) -> Bool
    ) -> [FinderMenuLayoutSection] {
        let favoriteIds = actions
            .filter(isFavorite)
            .sortedForMenu()
            .map(\.actionId)

        let regularIds = ActionCategory.allCases.flatMap { category in
            actions
                .filter { $0.category == category && !isFavorite($0) }
                .sortedForMenu()
                .map(\.actionId)
        }

        let ids = favoriteIds + regularIds
        return ids.isEmpty ? [] : [.directItems(actionIds: ids)]
    }

    private static func buildGroupedSections(
        actions: [MenuAction],
        isFavorite: (MenuAction) -> Bool
    ) -> [FinderMenuLayoutSection] {
        var sections: [FinderMenuLayoutSection] = []

        let favoriteIds = actions
            .filter(isFavorite)
            .sortedForMenu()
            .map(\.actionId)
        if !favoriteIds.isEmpty {
            sections.append(.submenu(title: "常用", actionIds: favoriteIds))
        }

        for category in ActionCategory.allCases {
            let ids = actions
                .filter { $0.category == category && !isFavorite($0) }
                .sortedForMenu()
                .map(\.actionId)
            if !ids.isEmpty {
                sections.append(.submenu(title: category.localizedName, actionIds: ids))
            }
        }

        return sections
    }
}

private extension Array where Element == MenuAction {
    func sortedForMenu() -> [MenuAction] {
        sorted {
            if $0.localizedTitle == $1.localizedTitle {
                return $0.actionId < $1.actionId
            }
            return $0.localizedTitle < $1.localizedTitle
        }
    }
}
