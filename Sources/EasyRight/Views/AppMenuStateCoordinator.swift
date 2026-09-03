import Foundation
import SwiftUI
import Combine
import AppKit

/// 集中式响应式状态协调器 (AppMenuStateCoordinator)
/// 统一管理动作资源库 (allActions)、当前菜单画布编排 (canvasItems)、筛选/检索与选区状态，
/// 并提供乐观更新与防抖持久化能力，与 SharedStorageManager 及系统 IPC 无缝同步。
@MainActor
public final class AppMenuStateCoordinator: ObservableObject {
    public static let shared = AppMenuStateCoordinator()

    // MARK: - Published State Properties

    /// 当前画布中编排的菜单项（动作、分隔符、子菜单）
    @Published public var canvasItems: [MenuCanvasItem] = []

    /// 用户自定义添加的外部应用动作实体
    @Published public var customAppActions: [CustomAppAction] = []

    /// 系统支持的全量内置与自定义动作库
    @Published public var allActions: [MenuAction] = []

    /// 当前在检查器或列表中选中的动作 ID
    @Published public var selectedActionId: String? = nil

    /// 搜索过滤词（与 filterText 保持双向同步）
    @Published public var searchQuery: String = "" {
        didSet {
            if filterText != searchQuery {
                filterText = searchQuery
            }
        }
    }

    /// 过滤文本（保持与 searchQuery 同步以提供灵活接口兼容）
    @Published public var filterText: String = "" {
        didSet {
            if searchQuery != filterText {
                searchQuery = filterText
            }
        }
    }

    /// 当前选中的分类过滤器；nil 表示“全部 (All)”
    @Published public var selectedCategory: ActionCategory? = nil

    /// 是否在动作画布中显示 1:1 实时原生菜单预览面板 (Issue 06)
    @Published public var isLivePreviewPresented: Bool = true

    // MARK: - Internal Storage & Debounce State

    private let storage: SharedStorageManager
    private var saveTask: Task<Void, Never>?
    private var isInternalSaving: Bool = false

    private var distributedObserver: NSObjectProtocol?
    private var appActiveObserver: NSObjectProtocol?
    private var appAvailabilityObserver: NSObjectProtocol?

    // MARK: - Initialization & Lifecycle

    public init(storage: SharedStorageManager = .shared) {
        self.storage = storage
        self.customAppActions = storage.getCustomAppActions()
        self.canvasItems = storage.getCanvasItems() ?? storage.defaultCanvasItems()
        self.allActions = DefaultActionRegistry.allActions

        setupNotificationObservers()
    }

    deinit {
        if let distributedObserver {
            DistributedNotificationCenter.default().removeObserver(distributedObserver)
        }
        if let appActiveObserver {
            NotificationCenter.default.removeObserver(appActiveObserver)
        }
        if let appAvailabilityObserver {
            NotificationCenter.default.removeObserver(appAvailabilityObserver)
        }
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        // 1. 跨进程配置变更通知
        distributedObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.easyright.app.configChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadFromStorage()
            }
        }

        // 2. 主 App 激活回到前台
        appActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadFromStorage()
            }
        }

        // 3. 外部关联应用就绪/安装状态变更
        appAvailabilityObserver = NotificationCenter.default.addObserver(
            forName: InstalledAppRegistry.availabilityChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.reloadFromStorage()
            }
        }
    }

    // MARK: - Filtering & Accessors

    /// 经过分类与关键词过滤后的动作列表
    public var filteredActions: [MenuAction] {
        allActions.filter { action in
            // 1. 分类匹配
            if let selectedCategory, action.category != selectedCategory {
                return false
            }

            // 2. 搜索词匹配
            let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if query.isEmpty {
                return true
            }

            if action.localizedTitle.localizedCaseInsensitiveContains(query) {
                return true
            }
            if action.actionId.localizedCaseInsensitiveContains(query) {
                return true
            }
            if action.category.localizedName.localizedCaseInsensitiveContains(query) {
                return true
            }
            return false
        }
    }

    /// 获取指定 ID 的动作实例
    public func action(for id: String) -> MenuAction? {
        allActions.first { $0.actionId == id }
    }

    /// 当前选中的动作实例
    public var selectedAction: MenuAction? {
        guard let selectedActionId else { return nil }
        return action(for: selectedActionId)
    }

    /// 已上架（处于画布中）的动作总数
    public var stagedActionCount: Int {
        var count = 0
        for item in canvasItems {
            switch item {
            case .action:
                count += 1
            case .submenu(_, _, let actionIds):
                count += actionIds.count
            case .separator:
                break
            }
        }
        return count
    }

    // MARK: - Canvas Operations

    /// 判断某个动作是否已被编排到画布中（包含顶层与子菜单）
    public func isActionStaged(actionId: String) -> Bool {
        canvasItems.contains { item in
            switch item {
            case .action(let id):
                return id == actionId
            case .separator:
                return false
            case .submenu(_, _, let actionIds):
                return actionIds.contains(actionId)
            }
        }
    }

    /// 切换某个动作的上架状态：若已存在则移除，不存在则追加到末尾
    public func toggleAction(actionId: String) {
        if isActionStaged(actionId: actionId) {
            removeAction(actionId: actionId)
        } else {
            canvasItems.append(.action(actionId: actionId))
            scheduleSave()
        }
    }

    /// 移除所有包含该 actionId 的菜单项或子菜单条目
    public func removeAction(actionId: String) {
        var updated: [MenuCanvasItem] = []
        for item in canvasItems {
            switch item {
            case .action(let id):
                if id != actionId {
                    updated.append(item)
                }
            case .separator:
                updated.append(item)
            case .submenu(let id, let title, let actionIds):
                let filteredIds = actionIds.filter { $0 != actionId }
                updated.append(.submenu(id: id, title: title, actionIds: filteredIds))
            }
        }
        canvasItems = updated
        scheduleSave()
    }

    /// 在指定位置插入动作项
    public func insertAction(actionId: String, at index: Int) {
        let newItem = MenuCanvasItem.action(actionId: actionId)
        if index >= 0 && index <= canvasItems.count {
            canvasItems.insert(newItem, at: index)
        } else {
            canvasItems.append(newItem)
        }
        scheduleSave()
    }

    /// 插入原生分隔线；若未指定 index 则追加至末尾
    public func addSeparator(at index: Int? = nil) {
        let newItem = MenuCanvasItem.separator(id: UUID())
        if let index = index, index >= 0 && index <= canvasItems.count {
            canvasItems.insert(newItem, at: index)
        } else {
            canvasItems.append(newItem)
        }
        scheduleSave()
    }

    /// 按索引移除画布项
    public func removeCanvasItem(at index: Int) {
        guard canvasItems.indices.contains(index) else { return }
        canvasItems.remove(at: index)
        scheduleSave()
    }

    /// 按项目唯一 ID 移除画布项
    public func removeCanvasItem(id: String) {
        canvasItems.removeAll { $0.id == id }
        scheduleSave()
    }

    /// 拖拽重排画布项
    public func moveCanvasItem(fromOffsets: IndexSet, toOffset: Int) {
        canvasItems.move(fromOffsets: fromOffsets, toOffset: toOffset)
        scheduleSave()
    }

    /// 单项重排
    public func moveCanvasItem(fromIndex: Int, toIndex: Int) {
        guard canvasItems.indices.contains(fromIndex) else { return }
        let target = max(0, min(toIndex, canvasItems.count - 1))
        guard fromIndex != target else { return }
        let item = canvasItems.remove(at: fromIndex)
        canvasItems.insert(item, at: target)
        scheduleSave()
    }

    /// 重置画布为系统默认菜单排列
    public func resetToDefault() {
        canvasItems = storage.defaultCanvasItems()
        scheduleSave()
    }

    /// 应用指定的预设方案重置画布菜单
    public func applyPreset(_ preset: StarterPreset) {
        canvasItems = preset.canvasItems()
        _ = storage.saveCanvasItems(canvasItems, postNotification: true)
        scheduleSave()
        SystemReloader.postConfigChanged()
    }

    /// 当前画布对应的预设微徽标名称 (Mini / Dev / Max / User)
    public var activePresetBadgeName: String {
        if canvasItems.matchesPresetStructure(StarterPreset.minimalist.canvasItems()) {
            return StarterPreset.minimalist.badgeName
        } else if canvasItems.matchesPresetStructure(StarterPreset.developer.canvasItems()) {
            return StarterPreset.developer.badgeName
        } else if canvasItems.matchesPresetStructure(StarterPreset.powerUser.canvasItems()) {
            return StarterPreset.powerUser.badgeName
        } else {
            return "User"
        }
    }

    /// 清空画布中的所有菜单项
    public func clearAll() {
        canvasItems.removeAll()
        scheduleSave()
    }

    /// 切换 1:1 实时原生菜单预览面板的展开/收起状态
    public func toggleLivePreview() {
        isLivePreviewPresented.toggle()
    }

    /// 快捷添加常用推荐动作（代表性精选动作与分组）
    public func addRecommendedActions() {
        canvasItems = storage.defaultCanvasItems()
        scheduleSave()
    }

    /// 处理拖拽放置（来自 ActionLibraryView 的 actionId，或来自 Canvas 内部项的 item.id）
    public func handleDrop(identifier: String, at targetIndex: Int) {
        let clampedTarget = max(0, min(targetIndex, canvasItems.count))

        // 1. 画布内现有项按 item.id 匹配 (如 action:xxx, separator:uuid, submenu:uuid)
        if let existingIndex = canvasItems.firstIndex(where: { $0.id == identifier }) {
            if existingIndex == clampedTarget || (existingIndex == clampedTarget - 1 && clampedTarget == canvasItems.count) {
                return
            }
            let item = canvasItems.remove(at: existingIndex)
            let insertIndex = existingIndex < clampedTarget ? (clampedTarget - 1) : clampedTarget
            let safeInsertIndex = max(0, min(insertIndex, canvasItems.count))
            canvasItems.insert(item, at: safeInsertIndex)
            scheduleSave()
            return
        }

        // 2. 检查是否为 actionId（未带前缀或带有 action: 前缀）
        let rawActionId = identifier.hasPrefix("action:") ? String(identifier.dropFirst(7)) : identifier

        // 若已经在画布中，则重排
        if let existingIndex = canvasItems.firstIndex(where: { $0.actionId == rawActionId }) {
            if existingIndex == clampedTarget || (existingIndex == clampedTarget - 1 && clampedTarget == canvasItems.count) {
                return
            }
            let item = canvasItems.remove(at: existingIndex)
            let insertIndex = existingIndex < clampedTarget ? (clampedTarget - 1) : clampedTarget
            let safeInsertIndex = max(0, min(insertIndex, canvasItems.count))
            canvasItems.insert(item, at: safeInsertIndex)
            scheduleSave()
            return
        }

        // 3. 若为新动作，则在指定位置插入
        if allActions.contains(where: { $0.actionId == rawActionId }) {
            insertAction(actionId: rawActionId, at: clampedTarget)
        }
    }

    // MARK: - Persistence & Storage Synchronization

    /// 防抖/即时提交变更至 SharedStorageManager
    public func scheduleSave(immediate: Bool = false) {
        if immediate {
            saveTask?.cancel()
            saveTask = nil
            persistCurrentState()
            return
        }

        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 150_000_000) // 150ms 防抖
            } catch {
                return
            }
            guard !Task.isCancelled, let self = self else { return }
            self.persistCurrentState()
        }
    }

    /// 立即强制刷新未落盘的修改
    public func flushPendingSave() {
        saveTask?.cancel()
        saveTask = nil
        persistCurrentState()
    }

    private func persistCurrentState() {
        isInternalSaving = true
        _ = storage.saveCanvasItems(canvasItems, postNotification: true)
        isInternalSaving = false
    }

    /// 从共享存储权威重新载入配置
    public func reloadFromStorage() {
        guard !isInternalSaving else { return }
        customAppActions = storage.getCustomAppActions()
        let stored = storage.getCanvasItems() ?? storage.defaultCanvasItems()
        if stored != canvasItems {
            canvasItems = stored
        }
        allActions = DefaultActionRegistry.allActions
    }

    // MARK: - Custom App Actions Management

    /// 添加新的自定义应用动作
    public func addCustomAppAction(_ action: CustomAppAction) {
        customAppActions.append(action)
        _ = storage.saveCustomAppActions(customAppActions, postNotification: true)
        allActions = DefaultActionRegistry.allActions
        ActionDispatcher.shared.register(action: CustomAppOpenAction(customApp: action))
        
        let actionId = "easyright.action.customapp.\(action.id.uuidString)"
        if !canvasItems.contains(where: { $0.actionId == actionId }) {
            canvasItems.append(.action(actionId: actionId))
            scheduleSave(immediate: true)
        }
    }

    /// 更新已有的自定义应用动作
    public func updateCustomAppAction(_ action: CustomAppAction) {
        guard let idx = customAppActions.firstIndex(where: { $0.id == action.id }) else { return }
        customAppActions[idx] = action
        _ = storage.saveCustomAppActions(customAppActions, postNotification: true)
        allActions = DefaultActionRegistry.allActions
        ActionDispatcher.shared.register(action: CustomAppOpenAction(customApp: action))
        scheduleSave(immediate: false)
    }

    /// 删除指定的自定义应用动作
    public func removeCustomAppAction(id: UUID) {
        customAppActions.removeAll { $0.id == id }
        _ = storage.saveCustomAppActions(customAppActions, postNotification: true)
        let actionId = "easyright.action.customapp.\(id.uuidString)"
        ActionDispatcher.shared.unregister(actionId: actionId)
        canvasItems.removeAll { $0.actionId == actionId }
        allActions = DefaultActionRegistry.allActions
        scheduleSave(immediate: true)
    }

    /// 清空所有自定义应用动作与对应配置文件
    public func clearAllCustomAppActions() {
        for action in customAppActions {
            let actionId = "easyright.action.customapp.\(action.id.uuidString)"
            ActionDispatcher.shared.unregister(actionId: actionId)
            canvasItems.removeAll { $0.actionId == actionId }
        }
        customAppActions.removeAll()
        _ = storage.saveCustomAppActions([], postNotification: true)
        _ = storage.removeValue(forKey: SharedStorageManager.Keys.customAppActions)
        allActions = DefaultActionRegistry.allActions
        scheduleSave(immediate: true)
    }
}

extension Array where Element == MenuCanvasItem {
    public func matchesPresetStructure(_ presetItems: [MenuCanvasItem]) -> Bool {
        guard count == presetItems.count else { return false }
        for (a, b) in zip(self, presetItems) {
            switch (a, b) {
            case (.action(let id1), .action(let id2)):
                if id1 != id2 { return false }
            case (.separator, .separator):
                continue
            case (.submenu(_, let t1, let ids1), .submenu(_, let t2, let ids2)):
                if t1 != t2 || ids1 != ids2 { return false }
            default:
                return false
            }
        }
        return true
    }
}
