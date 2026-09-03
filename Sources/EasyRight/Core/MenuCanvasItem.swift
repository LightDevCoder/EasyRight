import Foundation

/// 菜单画布项目数据模型，支持单个动作、原生分隔线与二级子菜单。
/// 用于持久化用户在画布中自由拖拽排序、分组与插入分隔符的菜单结构。
public enum MenuCanvasItem: Codable, Equatable, Identifiable, Sendable {
    case action(actionId: String)
    case separator(id: UUID)
    case submenu(id: UUID, title: String, actionIds: [String])

    // MARK: - Identifiable & Helpers

    public var id: String {
        switch self {
        case .action(let actionId):
            return "action:\(actionId)"
        case .separator(let id):
            return "separator:\(id.uuidString)"
        case .submenu(let id, _, _):
            return "submenu:\(id.uuidString)"
        }
    }

    public var isSeparator: Bool {
        if case .separator = self { return true }
        return false
    }

    public var isAction: Bool {
        if case .action = self { return true }
        return false
    }

    public var isSubmenu: Bool {
        if case .submenu = self { return true }
        return false
    }

    public var actionId: String? {
        if case .action(let actionId) = self { return actionId }
        return nil
    }

    public var title: String? {
        if case .submenu(_, let title, _) = self { return title }
        return nil
    }

    public var actionIds: [String] {
        switch self {
        case .action(let actionId):
            return [actionId]
        case .separator:
            return []
        case .submenu(_, _, let actionIds):
            return actionIds
        }
    }

    public var uuid: UUID? {
        switch self {
        case .action:
            return nil
        case .separator(let id):
            return id
        case .submenu(let id, _, _):
            return id
        }
    }

    // MARK: - Convenience Initializers

    public static func separator() -> MenuCanvasItem {
        .separator(id: UUID())
    }

    public static func submenu(title: String, actionIds: [String] = []) -> MenuCanvasItem {
        .submenu(id: UUID(), title: title, actionIds: actionIds)
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case actionId
        case id
        case title
        case actionIds
        // Fallback keys for synthesized enum representations
        case action
        case separator
        case submenu
    }

    private enum ItemType: String, Codable {
        case action
        case separator
        case submenu
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .action(let actionId):
            try container.encode(ItemType.action, forKey: .type)
            try container.encode(actionId, forKey: .actionId)
        case .separator(let id):
            try container.encode(ItemType.separator, forKey: .type)
            try container.encode(id, forKey: .id)
        case .submenu(let id, let title, let actionIds):
            try container.encode(ItemType.submenu, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(title, forKey: .title)
            try container.encode(actionIds, forKey: .actionIds)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 优先解析标准类型标签
        if let type = try? container.decode(ItemType.self, forKey: .type) {
            switch type {
            case .action:
                let actionId = try container.decode(String.self, forKey: .actionId)
                self = .action(actionId: actionId)
                return
            case .separator:
                let id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
                self = .separator(id: id)
                return
            case .submenu:
                let id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
                let title = (try? container.decode(String.self, forKey: .title)) ?? ""
                let actionIds = (try? container.decode([String].self, forKey: .actionIds)) ?? []
                self = .submenu(id: id, title: title, actionIds: actionIds)
                return
            }
        }

        // 容错解析：根据存在的键推断类型
        if let actionId = try? container.decode(String.self, forKey: .actionId) {
            self = .action(actionId: actionId)
        } else if let title = try? container.decode(String.self, forKey: .title) {
            let id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
            let actionIds = (try? container.decode([String].self, forKey: .actionIds)) ?? []
            self = .submenu(id: id, title: title, actionIds: actionIds)
        } else if let id = try? container.decode(UUID.self, forKey: .id) {
            self = .separator(id: id)
        } else {
            // 最简分隔符兜底
            self = .separator(id: UUID())
        }
    }
}
