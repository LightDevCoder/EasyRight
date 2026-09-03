import Foundation

/// 双向唯一整数 Tag 映射表，用于 FinderSync 菜单项点击分发。
/// 使用稳定的整数 tag 传递菜单动作标识，避免依赖 NSMenuItem.representedObject，
/// 并确保在动态重排序、插入分隔线与子菜单层级变化时动作分发保持准确一致。
public final class ActionTagMapper: @unchecked Sendable {
    public struct MenuSelection: Equatable, Sendable {
        public let actionId: String
        public let invocationKind: ActionInvocationKind

        public init(actionId: String, invocationKind: ActionInvocationKind) {
            self.actionId = actionId
            self.invocationKind = invocationKind
        }
    }

    private static let lock = NSLock()
    private nonisolated(unsafe) static var tagToSelection: [Int: MenuSelection] = [:]
    private nonisolated(unsafe) static var nextTag: Int = 1000

    public static func getTag(
        for actionId: String,
        invocationKind: ActionInvocationKind
    ) -> Int {
        lock.lock()
        defer { lock.unlock() }

        let selection = MenuSelection(actionId: actionId, invocationKind: invocationKind)
        if let existingTag = tagToSelection.first(where: { $0.value == selection })?.key {
            return existingTag
        }
        let assignedTag = nextTag
        tagToSelection[assignedTag] = selection
        nextTag += 1
        return assignedTag
    }

    public static func getSelection(for tag: Int) -> MenuSelection? {
        lock.lock()
        defer { lock.unlock() }
        return tagToSelection[tag]
    }

    public static func resetForTesting() {
        lock.lock()
        defer { lock.unlock() }
        tagToSelection.removeAll()
        nextTag = 1000
    }
}
