import SwiftUI
import AppKit

// MARK: - Action Target Availability Scope Model
/// 动作支持的目标上下文范围
public enum ActionTargetScope: String, CaseIterable, Identifiable, Sendable {
    case singleFile = "singleFile"
    case multipleFiles = "multipleFiles"
    case directory = "directory"
    case blankArea = "blankArea"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .singleFile: return L10n.tr("单个文件", "Single File")
        case .multipleFiles: return L10n.tr("多个文件", "Multiple Files")
        case .directory: return L10n.tr("文件夹", "Folder")
        case .blankArea: return L10n.tr("空白区域", "Blank Area")
        }
    }

    public var iconName: String {
        switch self {
        case .singleFile: return "doc"
        case .multipleFiles: return "doc.on.doc"
        case .directory: return "folder"
        case .blankArea: return "macwindow"
        }
    }

    public var scopeDescription: String {
        switch self {
        case .singleFile: return "在访达中右键单个文件时呈现"
        case .multipleFiles: return "多选多个文件时批量处理"
        case .directory: return "右键文件夹或目录项目"
        case .blankArea: return "在访达窗口或桌面空白背景右键"
        }
    }
}

/// 目标范围可用性判断结果
public struct ActionScopeAvailability: Identifiable, Sendable {
    public let scope: ActionTargetScope
    public let isSupported: Bool
    public let note: String

    public var id: String { scope.id }

    public init(scope: ActionTargetScope, isSupported: Bool, note: String) {
        self.scope = scope
        self.isSupported = isSupported
        self.note = note
    }
}

// MARK: - MenuAction Scope Evaluation Extension
public extension MenuAction {
    /// 评估动作在四种标准目标范围下的可用性
    var targetScopeAvailabilities: [ActionScopeAvailability] {
        let singleFileAvail = evaluateScope(.singleFile)
        let multiFilesAvail = evaluateScope(.multipleFiles)
        let directoryAvail = evaluateScope(.directory)
        let blankAreaAvail = evaluateScope(.blankArea)

        return [singleFileAvail, multiFilesAvail, directoryAvail, blankAreaAvail]
    }

    private func evaluateScope(_ scope: ActionTargetScope) -> ActionScopeAvailability {
        switch category {
        case .newFile:
            switch scope {
            case .singleFile:
                return ActionScopeAvailability(
                    scope: scope,
                    isSupported: true,
                    note: "在文件所在同级目录创建新文件"
                )
            case .multipleFiles:
                return ActionScopeAvailability(
                    scope: scope,
                    isSupported: true,
                    note: "在所选项目同级目录创建新文件"
                )
            case .directory:
                return ActionScopeAvailability(
                    scope: scope,
                    isSupported: true,
                    note: "直接在该文件夹内部创建新文件"
                )
            case .blankArea:
                return ActionScopeAvailability(
                    scope: scope,
                    isSupported: true,
                    note: "在当前打开的目录或桌面空白处创建"
                )
            }

        case .terminal:
            switch scope {
            case .singleFile:
                return ActionScopeAvailability(
                    scope: scope,
                    isSupported: true,
                    note: "在所选文件所在的父级目录启动应用"
                )
            case .multipleFiles:
                return ActionScopeAvailability(
                    scope: scope,
                    isSupported: true,
                    note: "以第一个文件所在目录作为工作区打开"
                )
            case .directory:
                return ActionScopeAvailability(
                    scope: scope,
                    isSupported: true,
                    note: "以所选文件夹作为工作目录直接打开"
                )
            case .blankArea:
                return ActionScopeAvailability(
                    scope: scope,
                    isSupported: true,
                    note: "在当前访达窗口所在路径启动打开"
                )
            }

        case .fileManage:
            let id = actionId.lowercased()
            if id.contains("paste") {
                switch scope {
                case .singleFile:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: false,
                        note: "无法粘贴至普通单文件内部"
                    )
                case .multipleFiles:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: false,
                        note: "多选文件时不可直接执行粘贴"
                    )
                case .directory:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "剪切板有内容时粘贴至目标文件夹"
                    )
                case .blankArea:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "剪切板有内容时粘贴至当前空白容器"
                    )
                }
            } else if id.contains("copypath") || id.contains("shellescaped") {
                switch scope {
                case .singleFile:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "拷贝所选单个文件的路径"
                    )
                case .multipleFiles:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "批量换行拷贝所有选中的文件路径"
                    )
                case .directory:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "拷贝所选文件夹目录路径"
                    )
                case .blankArea:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "在空白处右键拷贝当前文件夹路径"
                    )
                }
            } else if id.contains("copy") || id.contains("cut") || id.contains("delete") || id.contains("moveto") || id.contains("copyto") || id.contains("pathcopy") {
                switch scope {
                case .singleFile:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "针对单个文件执行操作"
                    )
                case .multipleFiles:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "批量针对所有选中的文件执行"
                    )
                case .directory:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "针对文件夹目录项目执行"
                    )
                case .blankArea:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: false,
                        note: "空白区域无选中目标时隐藏"
                    )
                }
            }
            return ActionScopeAvailability(scope: scope, isSupported: true, note: "支持常规文件管理")

        case .utility:
            let id = actionId.lowercased()
            if id.contains("hash") || id.contains("md5") || id.contains("sha") {
                switch scope {
                case .singleFile:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "计算单文件校验码并复制至剪贴板"
                    )
                case .multipleFiles:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: false,
                        note: "哈希校验目前仅支持单文件精准计算"
                    )
                case .directory:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: false,
                        note: "目录非物理数据流，不支持直接哈希"
                    )
                case .blankArea:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: false,
                        note: "空白区域无目标文件，不适用"
                    )
                }
            } else if id.contains("convert") {
                switch scope {
                case .singleFile:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "转换所选单张图片格式"
                    )
                case .multipleFiles:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "批量转换所有选中的图像文件"
                    )
                case .directory:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: false,
                        note: "不直接转换文件夹目录"
                    )
                case .blankArea:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: false,
                        note: "空白区域无目标图片，不适用"
                    )
                }
            } else if id.contains("qr") {
                switch scope {
                case .singleFile:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "生成剪贴板文本或文件名二维码"
                    )
                case .multipleFiles:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "生成剪贴板内容二维码"
                    )
                case .directory:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "生成剪贴板内容二维码"
                    )
                case .blankArea:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "在任意空白处快速调起二维码面板"
                    )
                }
            } else if id.contains("hidden") {
                switch scope {
                case .singleFile, .multipleFiles, .directory, .blankArea:
                    return ActionScopeAvailability(
                        scope: scope,
                        isSupported: true,
                        note: "全局系统级切换，在任意场景均生效"
                    )
                }
            }
            return ActionScopeAvailability(scope: scope, isSupported: true, note: "实用工具常规支持")
        }
    }
}

// MARK: - Action Inspector View
/// 上下文动作参数检查器面板 (ActionInspectorView)
/// 呈现选中动作的元数据、上架切换、适用目标范围规则、参数绑定配置与安全权限说明。
@MainActor
public struct ActionInspectorView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    @State private var copiedActionId: Bool = false

    @MainActor
    public init(coordinator: AppMenuStateCoordinator) {
        self.coordinator = coordinator
    }

    @MainActor
    public init() {
        self.coordinator = .shared
    }

    private var selectedAction: MenuAction? {
        coordinator.selectedAction
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. 检查器顶部导航栏
            inspectorHeader

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 2. 主体内容区（选区详情 / 空态占位）
            ZStack {
                if let action = selectedAction {
                    actionDetailsScrollView(action: action)
                } else {
                    emptyInspectorPlaceholder
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            minWidth: 240,
            idealWidth: DesignTokens.Layout.inspectorWidth,
            maxWidth: 320
        )
        .background(DesignTokens.Colors.controlBackground.opacity(0.35))
    }

    // MARK: - Inspector Header
    private var inspectorHeader: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: DesignTokens.Icon.small))
                    .foregroundStyle(Color.accentColor)

                Text(L10n.tr("动作详情", "Action Details"))
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)
            }

            Spacer()

            if selectedAction != nil {
                Button {
                    withAnimation(DesignTokens.AnimationToken.quickSpring) {
                        coordinator.selectedActionId = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                        .padding(5)
                        .background(
                            Circle()
                                .fill(DesignTokens.Colors.subtleFill)
                        )
                }
                .buttonStyle(.plain)
                .help(L10n.tr("关闭检查器", "Close Inspector"))
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .frame(height: 38)
        .background(DesignTokens.Colors.cardBackground.opacity(0.4))
    }

    // MARK: - Action Details Scroll View
    private func actionDetailsScrollView(action: MenuAction) -> some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // A. 动作基础信息与上架卡片
                actionHeaderCard(action: action)

                // B. 适用范围与触发条件 (Target Availability Scopes)
                targetAvailabilityCard(action: action)

                // C. 动作专属参数绑定与预览 (Action-Specific Parameter Bindings)
                parameterBindingsCard(action: action)

                // D. 权限与安全说明卡片
                securityAndBehaviorCard(action: action)
            }
            .padding(DesignTokens.Spacing.cardPadding)
        }
    }

    // MARK: - A. Action Header Card
    private func actionHeaderCard(action: MenuAction) -> some View {
        let isStaged = coordinator.isActionStaged(actionId: action.actionId)

        return VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // 大号动作图标
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.25),
                                    Color.accentColor.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: action.iconName ?? "command")
                        .font(.system(size: 22))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.accentColor)
                }

                // 标题与分类
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.localizedTitle)
                        .font(DesignTokens.Typography.headerTitle)
                        .foregroundStyle(DesignTokens.Colors.primaryText)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(action.category.localizedName)
                            .font(DesignTokens.Typography.captionBold)
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.subtleFill)
                            )

                        tierBadge(tier: action.tier)
                    }
                }

                Spacer()
            }

            // 内部 ID 展示与一键拷贝
            HStack {
                Text("标识符:")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)

                Text(action.actionId)
                    .font(DesignTokens.Typography.monospacedSmall)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(action.actionId, forType: .string)
                    copiedActionId = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copiedActionId = false
                    }
                } label: {
                    Image(systemName: copiedActionId ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundStyle(copiedActionId ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.tertiaryText)
                }
                .buttonStyle(.plain)
                .help("拷贝内部 Action ID")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                    .fill(DesignTokens.Colors.subtleFill)
            )

            // 上架状态与切换按钮
            Button {
                withAnimation(DesignTokens.AnimationToken.quickSpring) {
                    coordinator.toggleAction(actionId: action.actionId)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isStaged ? "checkmark.circle.fill" : "plus.circle")
                        .font(.system(size: 13, weight: .semibold))

                    Text(isStaged ? "已添加到菜单 (点击移除)" : "添加到菜单 (点击上架)")
                        .font(DesignTokens.Typography.bodyMedium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .foregroundStyle(isStaged ? .white : Color.accentColor)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .fill(isStaged ? Color.accentColor : DesignTokens.Colors.accentSubdued)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .stroke(
                            isStaged ? Color.clear : Color.accentColor.opacity(0.3),
                            lineWidth: DesignTokens.Stroke.hairline
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .studioCard()
    }

    // MARK: - B. Target Availability Scopes Card
    private func targetAvailabilityCard(action: MenuAction) -> some View {
        let availabilities = action.targetScopeAvailabilities

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: DesignTokens.Icon.small))
                    .foregroundStyle(Color.accentColor)

                Text("适用目标范围")
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Spacer()
            }

            VStack(spacing: 6) {
                ForEach(availabilities) { item in
                    HStack(alignment: .top, spacing: 8) {
                        // Scope Icon
                        Image(systemName: item.scope.iconName)
                            .font(.system(size: 12))
                            .foregroundStyle(
                                item.isSupported ? Color.accentColor : DesignTokens.Colors.tertiaryText
                            )
                            .frame(width: 16, height: 16)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(item.scope.displayName)
                                    .font(DesignTokens.Typography.bodyBold)
                                    .foregroundStyle(
                                        item.isSupported ? DesignTokens.Colors.primaryText : DesignTokens.Colors.secondaryText
                                    )

                                Spacer()

                                // Support badge chip
                                if item.isSupported {
                                    HStack(spacing: 2) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                        Text("支持")
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                    .foregroundStyle(DesignTokens.Colors.statusGreen)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1.5)
                                    .background(
                                        Capsule()
                                            .fill(DesignTokens.Colors.statusGreenBackground)
                                    )
                                } else {
                                    Text("不适用")
                                        .font(.system(size: 10, weight: .regular))
                                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1.5)
                                        .background(
                                            Capsule()
                                                .fill(DesignTokens.Colors.subtleFill)
                                        )
                                }
                            }

                            Text(item.note)
                                .font(DesignTokens.Typography.caption2)
                                .foregroundStyle(DesignTokens.Colors.tertiaryText)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.panel, style: .continuous)
                            .fill(
                                item.isSupported ? DesignTokens.Colors.subtleFill : Color.clear
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.panel, style: .continuous)
                            .stroke(DesignTokens.Stroke.subtleBorder, lineWidth: DesignTokens.Stroke.hairline)
                    )
                }
            }
        }
        .studioCard()
    }

    // MARK: - C. Parameter Bindings Card
    @ViewBuilder
    private func parameterBindingsCard(action: MenuAction) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.below.rectangle")
                    .font(.system(size: DesignTokens.Icon.small))
                    .foregroundStyle(Color.accentColor)

                Text("参数绑定与执行配置")
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Spacer()
            }

            switch action.category {
            case .terminal:
                terminalParameterDetails(action: action)
            case .newFile:
                newFileParameterDetails(action: action)
            case .fileManage:
                fileManageParameterDetails(action: action)
            case .utility:
                utilityParameterDetails(action: action)
            }
        }
        .studioCard()
    }

    // MARK: - C1. Terminal & External IDE Parameters
    private func terminalParameterDetails(action: MenuAction) -> some View {
        let bundleId = action.associatedBundleIdentifier ?? "com.apple.Terminal"
        let isInstalled = InstalledAppRegistry.shared.isInstalled(bundleId)
        let appUrl = InstalledAppRegistry.shared.url(for: bundleId)

        return VStack(spacing: 8) {
            parameterRow(title: "目标应用", value: action.localizedTitle.replacingOccurrences(of: "在 ", with: "").replacingOccurrences(of: " 中打开", with: ""))
            parameterRow(title: "Bundle ID", value: bundleId, isMonospace: true)

            // 安装就绪状态
            HStack {
                Text("系统就绪状态")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(isInstalled ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusAmber)
                        .frame(width: 7, height: 7)

                    Text(isInstalled ? "已安装就绪" : "未检测到应用")
                        .font(DesignTokens.Typography.captionBold)
                        .foregroundStyle(isInstalled ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusAmber)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isInstalled ? DesignTokens.Colors.statusGreenBackground : DesignTokens.Colors.statusAmberBackground)
                )
            }

            if let path = appUrl?.path {
                parameterRow(title: "应用物理路径", value: path, isMonospace: true)
            }

            parameterRow(title: "调用传参协议", value: "NSWorkspace.OpenConfiguration(arguments: [path])")
            parameterRow(title: "执行模式", value: "异步拉起，无需 AppleScript 授权")
        }
    }

    // MARK: - C2. New File / Template Parameters
    private func newFileParameterDetails(action: MenuAction) -> some View {
        let extName: String
        let fileTypeDisplay: String
        let initialBytesCount: Int

        if let newFileAction = action as? NewFileAction {
            extName = newFileAction.fileType.extensionName
            fileTypeDisplay = newFileAction.fileType.displayName
            initialBytesCount = newFileAction.fileType.defaultEmptyBytes.count
        } else {
            extName = "txt"
            fileTypeDisplay = "文本文档"
            initialBytesCount = 0
        }

        return VStack(spacing: 8) {
            parameterRow(title: "模板格式", value: fileTypeDisplay)
            parameterRow(title: "文件扩展名", value: ".\(extName)", isMonospace: true)
            parameterRow(title: "默认文件名前缀", value: "未命名")

            // 实时文件名预览
            VStack(alignment: .leading, spacing: 4) {
                Text("生成文件名实时预览:")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)

                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.accentColor)

                    Text("未命名.\(extName)")
                        .font(DesignTokens.Typography.monospaced)
                        .foregroundStyle(DesignTokens.Colors.primaryText)

                    Spacer()

                    Text("冲突自动追加 (未命名 1.\(extName))")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .fill(DesignTokens.Colors.subtleFill)
                )
            }

            parameterRow(title: "初始骨架体积", value: initialBytesCount > 0 ? "\(initialBytesCount) 字节 (内置二进制模板)" : "0 字节 (纯空文本)")
            parameterRow(title: "完成后续动作", value: "在访达中自动定位并高亮新文件")
        }
    }

    // MARK: - C3. Path Copy & File Manage Parameters
    private func pathCopyInfo(actionId: String) -> (formatName: String, sampleOutput: String, delimiter: String) {
        let id = actionId.lowercased()
        if id.contains("shell") {
            return ("Shell 命令行安全转义路径", "'/Users/developer/My\\ Folder/File.txt'", "空格 (Space)")
        } else if id.contains("git") {
            return ("Git 仓库相对路径", "Sources/EasyRight/Views/ActionInspectorView.swift", "换行符 (\\n)")
        } else if id.contains("name") {
            return ("纯文件名 / 目录名", "Document.pdf", "换行符 (\\n)")
        } else {
            return ("POSIX 绝对路径", "/Users/developer/Documents/Document.pdf", "换行符 (\\n)")
        }
    }

    private func fileManageParameterDetails(action: MenuAction) -> some View {
        let id = action.actionId.lowercased()

        return VStack(spacing: 8) {
            if id.contains("pathcopy") || id.contains("copypath") || id.contains("copyname") {
                let info = pathCopyInfo(actionId: action.actionId)
                parameterRow(title: "拷贝格式", value: info.formatName)
                parameterRow(title: "多项分隔符", value: info.delimiter)

                VStack(alignment: .leading, spacing: 4) {
                    Text("剪贴板输出预览:")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)

                    HStack {
                        Text(info.sampleOutput)
                            .font(DesignTokens.Typography.monospacedSmall)
                            .foregroundStyle(Color.accentColor)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(DesignTokens.Colors.subtleFill)
                    )
                }

                parameterRow(title: "目标剪贴板", value: "NSPasteboard.general (.string)")
            } else if id.contains("delete") {
                parameterRow(title: "删除策略", value: "彻底删除 (直接 unlink，绕过废纸篓)")
                parameterRow(title: "安全确认", value: "弹窗强二次确认 + 全局模态互斥")
                parameterRow(title: "执行队列", value: "后台 DeletionRequestCoordinator 串行队列")
            } else if id.contains("cut") || id.contains("paste") {
                parameterRow(title: "剪切板媒介", value: "clipboard.json (带 UUID 快照版本校验)")
                parameterRow(title: "跨卷迁移策略", value: "Copy-Then-Delete 事务化降级 + 自动重命名")
            } else {
                parameterRow(title: "操作类型", value: "文件系统原生管理")
                parameterRow(title: "交互方式", value: "NSOpenPanel 目标目录拾取 + 二次确认")
            }
        }
    }

    // MARK: - C4. Utility Parameters
    private func utilityParameterDetails(action: MenuAction) -> some View {
        let id = action.actionId.lowercased()

        return VStack(spacing: 8) {
            if id.contains("md5") {
                parameterRow(title: "散列算法", value: "MD5 (128-bit)")
                parameterRow(title: "计算方式", value: "FileHashCalculator 流式读取 (低内存占用)")
                parameterRow(title: "输出格式", value: "32 位小写十六进制字符串")
                sampleHashPreview(hash: "e10adc3949ba59abbe56e057f20f883e")
            } else if id.contains("sha256") {
                parameterRow(title: "散列算法", value: "SHA-256 (256-bit CryptoKit)")
                parameterRow(title: "计算方式", value: "FileHashCalculator 流式校验")
                parameterRow(title: "输出格式", value: "64 位小写十六进制字符串")
                sampleHashPreview(hash: "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e")
            } else if id.contains("qr") {
                parameterRow(title: "数据来源", value: "系统剪贴板文本 (NSPasteboard)")
                parameterRow(title: "纠错级别", value: "H 级别 (最高 30% 容错冗余)")
                parameterRow(title: "图像生成", value: "CoreImage CIFilter (10x 高清矢量放大)")
                parameterRow(title: "交互呈现", value: "独立浮动窗口 + 一键拷贝/保存 PNG")
            } else if id.contains("convert") {
                let targetFormat = id.contains("png") ? "PNG" : "JPEG"
                parameterRow(title: "目标输出格式", value: targetFormat)
                parameterRow(title: "源格式兼容", value: "PNG, JPG, JPEG, WEBP, HEIC, TIFF, GIF, BMP")
                parameterRow(title: "输出位置", value: "源文件同级目录 (重名自动追加递增序号)")
            } else if id.contains("hidden") {
                parameterRow(title: "配置项", value: "com.apple.finder AppleShowAllFiles")
                parameterRow(title: "生效机制", value: "修改系统偏好后重启 Finder 进程")
            }
        }
    }

    private func sampleHashPreview(hash: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("输出样本预览:")
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

            HStack {
                Text(hash)
                    .font(DesignTokens.Typography.monospacedSmall)
                    .foregroundStyle(Color.accentColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                    .fill(DesignTokens.Colors.subtleFill)
            )
        }
    }

    // MARK: - D. Security & Behavior Card
    private func securityAndBehaviorCard(action: MenuAction) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: DesignTokens.Icon.small))
                    .foregroundStyle(action.isHighRisk ? DesignTokens.Colors.statusAmber : Color.accentColor)

                Text("权限与安全机制")
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Spacer()
            }

            VStack(spacing: 6) {
                // 风险警告
                if action.isHighRisk {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.Colors.statusAmber)
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("高风险操作提示")
                                .font(DesignTokens.Typography.bodyBold)
                                .foregroundStyle(DesignTokens.Colors.statusAmber)

                            Text(action.riskDescription ?? "此操作具有破坏性或会修改系统状态，请谨慎执行。")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.secondaryText)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.panel, style: .continuous)
                            .fill(DesignTokens.Colors.statusAmberBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.panel, style: .continuous)
                            .stroke(DesignTokens.Colors.statusAmberBorder, lineWidth: DesignTokens.Stroke.hairline)
                    )
                }

                // 目标存在性要求
                parameterRow(
                    title: "物理文件依赖",
                    value: action.requiresExistingTargets ? "必须选中已存在的实体文件/目录" : "无实体目标依赖 (独立全局动作)"
                )

                // 默认开启偏好
                parameterRow(
                    title: "默认启用策略",
                    value: action.isEnabledByDefault ? "系统默认开启" : "需用户手动开启"
                )

                // 权限需求
                parameterRow(
                    title: "建议授权",
                    value: "全盘访问权限 (Full Disk Access)"
                )
            }
        }
        .studioCard()
    }

    // MARK: - Helper UI Components
    private func parameterRow(title: String, value: String, isMonospace: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.secondaryText)
                .frame(width: 80, alignment: .leading)

            Spacer()

            Text(value)
                .font(isMonospace ? DesignTokens.Typography.monospacedSmall : DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private func tierBadge(tier: ActionTier) -> some View {
        let (label, color, bg) = {
            switch tier {
            case .essential:
                return ("基础", DesignTokens.Colors.statusGreen, DesignTokens.Colors.statusGreenBackground)
            case .professional:
                return ("专业", Color.accentColor, DesignTokens.Colors.accentSubdued)
            case .advanced:
                return ("高级", DesignTokens.Colors.statusAmber, DesignTokens.Colors.statusAmberBackground)
            }
        }()

        return Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(
                Capsule()
                    .fill(bg)
            )
    }

    // MARK: - Empty Inspector Placeholder
    private var emptyInspectorPlaceholder: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.subtleFill)
                    .frame(width: 56, height: 56)

                Image(systemName: "sidebar.right")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
            }

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(L10n.tr("选择动作以查看详情", "Select an Action for Details"))
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)

                Text(L10n.tr("在左侧资源库或中间画布点击任意动作，即可查看其适用场景、参数配置与权限要求。", "Click any action in the library or canvas to inspect rules, parameters, and permissions."))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
            }

            // Quick Tips
            VStack(alignment: .leading, spacing: 6) {
                tipRow(icon: "target", text: L10n.tr("检查单文件/多文件/空白处触发规则", "Inspect trigger rules for files and folders"))
                tipRow(icon: "terminal", text: L10n.tr("查看终端与编辑器关联应用状态", "Check terminal and editor application status"))
                tipRow(icon: "shield", text: L10n.tr("了解破坏性动作的高风险机制与权限", "Understand high-risk actions and permissions"))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.panel, style: .continuous)
                    .fill(DesignTokens.Colors.subtleFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.panel, style: .continuous)
                    .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
            )
            .frame(maxWidth: 240)
            .padding(.top, DesignTokens.Spacing.xs)

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color.accentColor)

            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(DesignTokens.Colors.secondaryText)
        }
    }
}
