import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - MenuAction Target Scope Extension
public extension MenuAction {
    var targetScopeDescription: String {
        switch category {
        case .newFile:
            return L10n.tr("空白/目录", "Blank / Folder")
        case .fileManage:
            if actionId.contains("paste") {
                return L10n.tr("剪贴板", "Clipboard")
            }
            return L10n.tr("文件/目录", "Files / Folders")
        case .terminal:
            return L10n.tr("目录/容器", "Folders / Packages")
        case .utility:
            if actionId.contains("qr") {
                return L10n.tr("剪贴/文本", "Clipboard / Text")
            } else if actionId.contains("convert") {
                return L10n.tr("图像文件", "Images")
            } else if actionId.contains("hash") || actionId.contains("md5") || actionId.contains("sha") {
                return L10n.tr("任意文件", "Any Files")
            }
            return L10n.tr("通用", "General")
        }
    }
}

// MARK: - Active Menu Canvas View
/// 已编排菜单画布视图 (ActiveMenuCanvasView)
/// 提供主右键菜单的可视化直接操纵工作区，支持拖拽排序、系统分隔符插入、二级子菜单编排以及即时 IPC 同步。
@MainActor
public struct ActiveMenuCanvasView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator

    @State private var targetedDropIndex: Int? = nil
    @State private var isBottomTargeted: Bool = false

    @MainActor
    public init(coordinator: AppMenuStateCoordinator) {
        self.coordinator = coordinator
    }

    @MainActor
    public init() {
        self.coordinator = .shared
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部画布操作栏
            canvasHeaderBar

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 2. 菜单画布内容区（列表 / 空态）
            ZStack {
                if coordinator.canvasItems.isEmpty {
                    emptyCanvasView
                } else {
                    canvasItemsScrollView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 3. 底部快捷状态栏
            bottomStatusBar
        }
        .background(DesignTokens.Colors.controlBackground.opacity(0.15))
    }

    // MARK: - Canvas Header Bar
    private var canvasHeaderBar: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // 标题与项目计数胶囊
            HStack(spacing: 6) {
                Text(L10n.tr("已编排菜单", "Menu Canvas"))
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)
                    .lineLimit(1)
                    .fixedSize()

                Text("\(coordinator.canvasItems.count)")
                    .font(DesignTokens.Typography.captionBold)
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(DesignTokens.Colors.accentSubdued)
                    )
            }

            Spacer(minLength: 4)

            // 响应式快捷动作按钮组：宽度充足时显示文字与图标，紧凑时自适应收缩为精炼图标
            ViewThatFits(in: .horizontal) {
                fullHeaderButtons
                compactHeaderButtons
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.cardBackground.opacity(0.4))
    }

    private var fullHeaderButtons: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            // + 添加分隔线
            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.addSeparator()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text(L10n.tr("添加分隔线", "Add Separator"))
                        .font(DesignTokens.Typography.captionMedium)
                        .lineLimit(1)
                        .fixedSize()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .fill(DesignTokens.Colors.subtleFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
            .help(L10n.tr("在菜单末尾插入一条系统分隔线", "Insert a system separator at the end of the menu"))

            // 恢复默认
            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.resetToDefault()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 10))
                    Text(L10n.tr("恢复默认", "Reset to Default"))
                        .font(DesignTokens.Typography.captionMedium)
                        .lineLimit(1)
                        .fixedSize()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .fill(DesignTokens.Colors.subtleFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
            .help(L10n.tr("重置菜单为默认动作组合", "Reset menu to default action layout"))

            // 清空
            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.clearAll()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                    Text(L10n.tr("清空", "Clear All"))
                        .font(DesignTokens.Typography.captionMedium)
                        .lineLimit(1)
                        .fixedSize()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(DesignTokens.Colors.statusRed)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .fill(DesignTokens.Colors.statusRedBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .stroke(DesignTokens.Colors.statusRedBorder, lineWidth: DesignTokens.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
            .help(L10n.tr("清空当前编排的所有项目", "Clear all staged items from the canvas"))

            // 实时预览切换
            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.toggleLivePreview()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: coordinator.isLivePreviewPresented ? "eye.fill" : "eye.slash")
                        .font(.system(size: 10))
                        .foregroundStyle(coordinator.isLivePreviewPresented ? Color.accentColor : DesignTokens.Colors.secondaryText)
                    Text(L10n.tr("实时预览", "Live Preview"))
                        .font(DesignTokens.Typography.captionMedium)
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(coordinator.isLivePreviewPresented ? DesignTokens.Colors.primaryText : DesignTokens.Colors.secondaryText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .fill(coordinator.isLivePreviewPresented ? DesignTokens.Colors.accentSubdued : DesignTokens.Colors.subtleFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .stroke(coordinator.isLivePreviewPresented ? Color.accentColor.opacity(0.3) : DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                )
            }
            .buttonStyle(.plain)
            .help(coordinator.isLivePreviewPresented ? L10n.tr("收起右侧实时原生菜单预览", "Hide 1:1 Live Preview") : L10n.tr("展开右侧实时原生菜单预览", "Show 1:1 Live Preview"))
        }
    }

    private var compactHeaderButtons: some View {
        HStack(spacing: 4) {
            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.addSeparator()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(DesignTokens.Colors.subtleFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                    )
            }
            .buttonStyle(.plain)
            .help("添加分隔线")

            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.resetToDefault()
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 11))
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(DesignTokens.Colors.subtleFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                    )
            }
            .buttonStyle(.plain)
            .help("恢复默认")

            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.clearAll()
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Colors.statusRed)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(DesignTokens.Colors.statusRedBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .stroke(DesignTokens.Colors.statusRedBorder, lineWidth: DesignTokens.Stroke.hairline)
                    )
            }
            .buttonStyle(.plain)
            .help("清空")

            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.toggleLivePreview()
                }
            } label: {
                Image(systemName: coordinator.isLivePreviewPresented ? "eye.fill" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundStyle(coordinator.isLivePreviewPresented ? Color.accentColor : DesignTokens.Colors.secondaryText)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(coordinator.isLivePreviewPresented ? DesignTokens.Colors.accentSubdued : DesignTokens.Colors.subtleFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .stroke(coordinator.isLivePreviewPresented ? Color.accentColor.opacity(0.3) : DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                    )
            }
            .buttonStyle(.plain)
            .help(coordinator.isLivePreviewPresented ? "收起实时预览" : "展开实时预览")
        }
    }

    // MARK: - Canvas Items Scroll View
    private var canvasItemsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(Array(coordinator.canvasItems.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 0) {
                        // 插入位指示器（拖拽悬停时显示）
                        if targetedDropIndex == index {
                            dropInsertionIndicator
                        }

                        // 具体菜单项行卡片
                        canvasItemRow(item: item, index: index)
                    }
                    .onDrop(
                        of: [.plainText, .text],
                        isTargeted: Binding(
                            get: { targetedDropIndex == index },
                            set: { targeted in
                                withAnimation(DesignTokens.springTransition) {
                                    if targeted {
                                        targetedDropIndex = index
                                    } else if targetedDropIndex == index {
                                        targetedDropIndex = nil
                                    }
                                }
                            }
                        ),
                        perform: { providers in
                            handleDrop(providers: providers, at: index)
                        }
                    )
                }

                // 末尾插入位指示器
                if targetedDropIndex == coordinator.canvasItems.count {
                    dropInsertionIndicator
                }

                // 底部留白与尾部拖拽接收区
                bottomDropTargetArea
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    // MARK: - Item Row Switcher
    @ViewBuilder
    private func canvasItemRow(item: MenuCanvasItem, index: Int) -> some View {
        switch item {
        case .action(let actionId):
            CanvasActionRowView(
                coordinator: coordinator,
                actionId: actionId,
                itemId: item.id,
                index: index,
                totalCount: coordinator.canvasItems.count
            )
        case .separator:
            CanvasSeparatorRowView(
                coordinator: coordinator,
                itemId: item.id,
                index: index,
                totalCount: coordinator.canvasItems.count
            )
        case .submenu(_, let title, let actionIds):
            CanvasSubmenuRowView(
                coordinator: coordinator,
                itemId: item.id,
                title: title,
                actionIds: actionIds,
                index: index,
                totalCount: coordinator.canvasItems.count
            )
        }
    }

    // MARK: - Drop Indicators & Areas
    private var dropInsertionIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: 2)
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 2)
        .transition(.opacity.combined(with: .scale))
    }

    private var bottomDropTargetArea: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .strokeBorder(
                    isBottomTargeted ? Color.accentColor : DesignTokens.Stroke.defaultBorder,
                    style: StrokeStyle(lineWidth: isBottomTargeted ? 1.5 : 1.0, dash: [4, 4])
                )
                .frame(height: 38)
                .overlay(
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(isBottomTargeted ? Color.accentColor : DesignTokens.Colors.tertiaryText)
                        Text(L10n.tr("拖拽至此添加到末尾", "Drag here to append to bottom"))
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(isBottomTargeted ? Color.accentColor : DesignTokens.Colors.tertiaryText)
                    }
                )
        }
        .padding(.top, 4)
        .onDrop(
            of: [.plainText, .text],
            isTargeted: Binding(
                get: { isBottomTargeted },
                set: { targeted in
                    withAnimation(DesignTokens.springTransition) {
                        isBottomTargeted = targeted
                        targetedDropIndex = targeted ? coordinator.canvasItems.count : nil
                    }
                }
            ),
            perform: { providers in
                handleDrop(providers: providers, at: coordinator.canvasItems.count)
            }
        )
    }

    // MARK: - Empty Canvas View
    private var emptyCanvasView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.subtleFill)
                    .frame(width: 56, height: 56)

                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 24))
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
            }

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(L10n.tr("菜单暂无编排动作", "No actions staged"))
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)

                Text(L10n.tr("从左侧动作资源库点击“+”或拖拽动作至此，也可一键添加常用推荐动作", "Click '+' or drag actions from the library here, or add recommended actions"))
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.addRecommendedActions()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11))
                    Text(L10n.tr("添加常用动作", "Add Recommended Actions"))
                        .font(DesignTokens.Typography.bodyMedium)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(.white)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(
            of: [.plainText, .text],
            isTargeted: nil,
            perform: { providers in
                handleDrop(providers: providers, at: 0)
            }
        )
    }

    // MARK: - Bottom Status Bar
    private var bottomStatusBar: some View {
        HStack {
            Text(L10n.tr("共 \(coordinator.canvasItems.count) 项 (\(coordinator.stagedActionCount) 动作)", "\(coordinator.canvasItems.count) Items (\(coordinator.stagedActionCount) Actions)"))
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.tertiaryText)
                .lineLimit(1)
                .fixedSize()

            Spacer(minLength: 4)

            Text(L10n.tr("支持自由拖拽重排与快速移除", "Drag to reorder or click to remove"))
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.tertiaryText)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, 6)
        .background(DesignTokens.Colors.cardBackground.opacity(0.3))
    }

    // MARK: - Drop Handling
    private func handleDrop(providers: [NSItemProvider], at targetIndex: Int) -> Bool {
        guard let provider = providers.first else { return false }
        if provider.canLoadObject(ofClass: NSString.self) {
            _ = provider.loadObject(ofClass: NSString.self) { stringItem, _ in
                guard let identifier = stringItem as? String else { return }
                Task { @MainActor in
                    withAnimation(DesignTokens.springTransition) {
                        coordinator.handleDrop(identifier: identifier, at: targetIndex)
                        targetedDropIndex = nil
                        isBottomTargeted = false
                    }
                }
            }
            return true
        }
        return false
    }
}

// MARK: - Canvas Action Row View
@MainActor
public struct CanvasActionRowView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    public let actionId: String
    public let itemId: String
    public let index: Int
    public let totalCount: Int

    @State private var isHovered: Bool = false

    public init(
        coordinator: AppMenuStateCoordinator,
        actionId: String,
        itemId: String,
        index: Int,
        totalCount: Int
    ) {
        self.coordinator = coordinator
        self.actionId = actionId
        self.itemId = itemId
        self.index = index
        self.totalCount = totalCount
    }

    private var action: MenuAction? {
        coordinator.action(for: actionId)
    }

    private var isSelected: Bool {
        coordinator.selectedActionId == actionId
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // A. 拖拽手柄
            Image(systemName: "line.3.horizontal")
                .font(.system(size: DesignTokens.Icon.small))
                .foregroundStyle(
                    isHovered ? DesignTokens.Colors.secondaryText : DesignTokens.Colors.tertiaryText.opacity(0.7)
                )
                .frame(width: 14)
                .help("拖拽重新排序")

            // B. 图标容器
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.20)
                            : DesignTokens.Colors.subtleFill
                    )
                    .frame(width: 26, height: 26)

                Image(systemName: action?.iconName ?? "command")
                    .font(.system(size: DesignTokens.Icon.standard))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? Color.accentColor : DesignTokens.Colors.primaryText)
            }

            // C. 动作标题与作用域徽章（自适应双行结构：标题独占整行，避免横向挤压截断）
            VStack(alignment: .leading, spacing: 2) {
                Text(action?.localizedTitle ?? actionId)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundStyle(DesignTokens.Colors.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(action?.localizedTitle ?? actionId)

                if let action = action {
                    HStack(spacing: 4) {
                        // 作用域徽章 (Target Scope Badge)
                        Text(action.targetScopeDescription)
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(DesignTokens.Colors.tertiaryText)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.tag, style: .continuous)
                                    .fill(DesignTokens.Colors.subtleFill)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.tag, style: .continuous)
                                    .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                            )

                        // 高风险徽章
                        if action.isHighRisk {
                            Text(L10n.tr("高风险", "High Risk"))
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(DesignTokens.Colors.statusAmber)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.tag, style: .continuous)
                                        .fill(DesignTokens.Colors.statusAmberBackground)
                                )
                        }
                    }
                }
            }

            Spacer()

            // D. 上下移动快捷按钮（悬浮时展示）
            if isHovered {
                HStack(spacing: 2) {
                    Button {
                        withAnimation(DesignTokens.springTransition) {
                            coordinator.moveCanvasItem(fromIndex: index, toIndex: index - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .disabled(index == 0)
                    .help("上移")

                    Button {
                        withAnimation(DesignTokens.springTransition) {
                            coordinator.moveCanvasItem(fromIndex: index, toIndex: index + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .disabled(index >= totalCount - 1)
                    .help("下移")
                }
                .transition(.opacity)
            }

            // E. 移除按钮
            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.removeCanvasItem(id: itemId)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        isHovered ? DesignTokens.Colors.statusRed : DesignTokens.Colors.tertiaryText
                    )
            }
            .buttonStyle(.plain)
            .help("从菜单中移除该动作")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(minHeight: 44, maxHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .fill(
                    isSelected
                        ? DesignTokens.Colors.cardBackgroundSelected
                        : (isHovered ? DesignTokens.Colors.cardBackgroundHover : DesignTokens.Colors.cardBackground)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .stroke(
                    isSelected ? DesignTokens.Stroke.prominentBorder : DesignTokens.Stroke.defaultBorder,
                    lineWidth: DesignTokens.Stroke.hairline
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            coordinator.selectedActionId = actionId
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrag {
            NSItemProvider(object: itemId as NSString)
        }
    }
}

// MARK: - Canvas Separator Row View
@MainActor
public struct CanvasSeparatorRowView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    public let itemId: String
    public let index: Int
    public let totalCount: Int

    @State private var isHovered: Bool = false

    public init(
        coordinator: AppMenuStateCoordinator,
        itemId: String,
        index: Int,
        totalCount: Int
    ) {
        self.coordinator = coordinator
        self.itemId = itemId
        self.index = index
        self.totalCount = totalCount
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // 拖拽手柄
            Image(systemName: "line.3.horizontal")
                .font(.system(size: DesignTokens.Icon.small))
                .foregroundStyle(
                    isHovered ? DesignTokens.Colors.secondaryText : DesignTokens.Colors.tertiaryText.opacity(0.7)
                )
                .frame(width: 14)

            // 分隔线视觉表达
            HStack(spacing: 8) {
                Rectangle()
                    .fill(DesignTokens.Colors.separator)
                    .frame(height: 1)

                Text(L10n.tr("── 分隔线 ──", "── Separator ──"))
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
                    .fixedSize()

                Rectangle()
                    .fill(DesignTokens.Colors.separator)
                    .frame(height: 1)
            }

            // 上下移动快捷按钮
            if isHovered {
                HStack(spacing: 2) {
                    Button {
                        withAnimation(DesignTokens.springTransition) {
                            coordinator.moveCanvasItem(fromIndex: index, toIndex: index - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .disabled(index == 0)

                    Button {
                        withAnimation(DesignTokens.springTransition) {
                            coordinator.moveCanvasItem(fromIndex: index, toIndex: index + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .disabled(index >= totalCount - 1)
                }
            }

            // 移除按钮
            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.removeCanvasItem(id: itemId)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        isHovered ? DesignTokens.Colors.statusRed : DesignTokens.Colors.tertiaryText
                    )
            }
            .buttonStyle(.plain)
            .help("移除此分隔线")
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .fill(isHovered ? DesignTokens.Colors.cardBackgroundHover : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrag {
            NSItemProvider(object: itemId as NSString)
        }
    }
}

// MARK: - Canvas Submenu Row View
@MainActor
public struct CanvasSubmenuRowView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    public let itemId: String
    public let title: String
    public let actionIds: [String]
    public let index: Int
    public let totalCount: Int

    @State private var isHovered: Bool = false

    public init(
        coordinator: AppMenuStateCoordinator,
        itemId: String,
        title: String,
        actionIds: [String],
        index: Int,
        totalCount: Int
    ) {
        self.coordinator = coordinator
        self.itemId = itemId
        self.title = title
        self.actionIds = actionIds
        self.index = index
        self.totalCount = totalCount
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // 拖拽手柄
            Image(systemName: "line.3.horizontal")
                .font(.system(size: DesignTokens.Icon.small))
                .foregroundStyle(
                    isHovered ? DesignTokens.Colors.secondaryText : DesignTokens.Colors.tertiaryText.opacity(0.7)
                )
                .frame(width: 14)

            // 子菜单图标
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(DesignTokens.Colors.subtleFill)
                    .frame(width: 26, height: 26)

                Image(systemName: "folder")
                    .font(.system(size: DesignTokens.Icon.standard))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.accentColor)
            }

            // 子菜单标题与内含动作摘要
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(title.isEmpty ? "子菜单" : title)
                        .font(DesignTokens.Typography.bodyBold)
                        .foregroundStyle(DesignTokens.Colors.primaryText)

                    Text("\(actionIds.count) 项")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.secondaryText)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.subtleFill)
                        )
                }

                if !actionIds.isEmpty {
                    Text(previewActionTitles)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 上下移动快捷按钮
            if isHovered {
                HStack(spacing: 2) {
                    Button {
                        withAnimation(DesignTokens.springTransition) {
                            coordinator.moveCanvasItem(fromIndex: index, toIndex: index - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .disabled(index == 0)

                    Button {
                        withAnimation(DesignTokens.springTransition) {
                            coordinator.moveCanvasItem(fromIndex: index, toIndex: index + 1)
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .disabled(index >= totalCount - 1)
                }
            }

            // 移除按钮
            Button {
                withAnimation(DesignTokens.springTransition) {
                    coordinator.removeCanvasItem(id: itemId)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        isHovered ? DesignTokens.Colors.statusRed : DesignTokens.Colors.tertiaryText
                    )
            }
            .buttonStyle(.plain)
            .help("移除此子菜单")
        }
        .padding(.horizontal, 10)
        .frame(height: DesignTokens.Layout.standardRowHeight)
        .frame(minHeight: DesignTokens.Layout.minRowHeight, maxHeight: DesignTokens.Layout.maxRowHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .fill(isHovered ? DesignTokens.Colors.cardBackgroundHover : DesignTokens.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrag {
            NSItemProvider(object: itemId as NSString)
        }
    }

    private var previewActionTitles: String {
        actionIds.compactMap { coordinator.action(for: $0)?.localizedTitle ?? $0 }.joined(separator: ", ")
    }
}
