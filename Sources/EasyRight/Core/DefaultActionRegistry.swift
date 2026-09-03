import Foundation

/// 内置动作的唯一清单。Host、FinderSync、设置页和测试均从这里取得相同实例集合。
public enum DefaultActionRegistry {
    public static var allActions: [MenuAction] {
        makeAllActions()
    }

    /// 返回 30 个内置原生动作
    public static func makeActions() -> [MenuAction] {
        let newFileActions: [MenuAction] = SupportedFileType.allCases.map {
            NewFileAction(fileType: $0)
        }
        let fileManageActions: [MenuAction] = [
            FileManageAction(type: .cut),
            FileManageAction(type: .paste),
            FileManageAction(type: .permanentDelete),
            FileManageAction(type: .copyPath),
            FileManageAction(type: .copyName),
            FileManageAction(type: .copyTo),
            FileManageAction(type: .moveTo),
            PathCopyAction(kind: .shellEscaped),
            PathCopyAction(kind: .gitRelative)
        ]
        let terminalActions: [MenuAction] = TerminalEditorType.allCases.map {
            TerminalOpenAction(type: $0)
        }
        let utilityActions: [MenuAction] = [
            UtilityAction(type: .calculateMD5),
            UtilityAction(type: .calculateSHA256),
            UtilityAction(type: .toggleHiddenFiles),
            UtilityAction(type: .textToQRCode),
            UtilityAction(type: .convertToPNG),
            UtilityAction(type: .convertToJPEG)
        ]

        return newFileActions + fileManageActions + terminalActions + utilityActions
    }

    /// 动态载入用户自定义的应用动作
    public static func makeCustomActions(storage: SharedStorageManager = .shared) -> [MenuAction] {
        let customs = storage.getCustomAppActions()
        return customs.map { CustomAppOpenAction(customApp: $0) }
    }

    /// 获取包含内置动作和用户自定义动作的全量动作列表
    public static func makeAllActions(storage: SharedStorageManager = .shared) -> [MenuAction] {
        return makeActions() + makeCustomActions(storage: storage)
    }

    @discardableResult
    public static func registerAll(into dispatcher: ActionDispatcher = .shared, storage: SharedStorageManager = .shared) -> [MenuAction] {
        let actions = makeAllActions(storage: storage)
        dispatcher.reset(with: actions)
        return actions
    }
}
