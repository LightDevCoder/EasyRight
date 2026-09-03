import SwiftUI
import AppKit

// MARK: - Menu Shortcut Mapper
/// 映射动作至原生 macOS 风格的快捷键提示文本
public enum MenuShortcutMapper {
    public static func shortcut(for actionId: String) -> String? {
        switch actionId {
        // 文件管理类
        case "file_manage_copy_path": return "⌥⌘C"
        case "file_manage_copy_name": return "⌥⌘N"
        case "file_manage_cut": return "⌘X"
        case "file_manage_paste": return "⌘V"
        case "file_manage_permanent_delete": return "⌥⌘⌫"
        case "file_manage_copy_to": return "⌥⌘F"
        case "file_manage_move_to": return "⌥⌘M"
        case "path_copy_shell_escaped": return "⌥⇧⌘C"
        case "path_copy_git_relative": return "⌃⌘C"

        // 终端与编辑器
        case "terminal_open_terminal": return "⌃⌥T"
        case "terminal_open_vscode": return "⌃⌥C"
        case "terminal_open_iterm": return "⌃⌥I"
        case "terminal_open_cursor": return "⌃⌥R"
        case "terminal_open_sublime": return "⌃⌥S"
        case "terminal_open_fleet": return "⌃⌥F"
        case "terminal_open_idea": return "⌃⌥J"

        // 实用小工具
        case "utility_toggle_hidden_files": return "⇧⌘."
        case "utility_calculate_md5": return "⌥⌘M"
        case "utility_calculate_sha256": return "⌥⌘S"
        case "utility_text_to_qrcode": return "⌥⌘Q"
        case "utility_convert_png": return "⌥⌘P"
        case "utility_convert_jpeg": return "⌥⌘J"

        // 新建文件
        case "new_file_txt": return "⌘N"
        case "new_file_docx": return "⌥⌘D"
        case "new_file_xlsx": return "⌥⌘X"
        case "new_file_pptx": return "⌥⌘P"
        case "new_file_markdown": return "⌥⌘K"

        default:
            return nil
        }
    }
}

// MARK: - Live Menu Mockup View
/// 1:1 实时原生右键菜单仿真模拟器 (LiveMenuMockupView)
/// 精确再现 macOS 真实 NSMenu 几何参数、毛玻璃亚克力材质、阴影层次与交互高亮状态，
/// 与 AppMenuStateCoordinator 保持 60fps 零延迟双向响应同步。
@MainActor
public struct LiveMenuMockupView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator

    public static let menuWidth: CGFloat = 236
    public static let cornerRadius: CGFloat = 9
    public static let rowHeight: CGFloat = 24
    public static let highlightRadius: CGFloat = 4

    @State private var hoveredItemId: String? = nil
    @State private var hoveredSubmenuId: String? = nil

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
            // 1. 顶部预览状态标头 (Header Banner)
            headerBanner

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 2. 仿真菜单居中画布区 (Simulated Desktop Canvas)
            ScrollView([.vertical, .horizontal], showsIndicators: false) {
                VStack {
                    Spacer(minLength: 16)

                    HStack {
                        Spacer(minLength: 16)

                        // 真实 NSMenu 仿真弹出层
                        simulatedMenuContainer

                        Spacer(minLength: 16)
                    }

                    Spacer(minLength: 16)
                }
                .frame(minWidth: Self.menuWidth + 48, minHeight: 380)
            }
            .background(
                ZStack {
                    // 模拟桌面淡雅背景基底
                    DesignTokens.Colors.controlBackground.opacity(0.12)

                    // 极其微弱的网格点阵底纹，增强拟真景深感
                    CanvasGridPattern()
                        .opacity(0.15)
                }
            )

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 3. 底部操作小贴士
            footerHintBar
        }
        .background(DesignTokens.Colors.cardBackground.opacity(0.2))
    }

    // MARK: - Header Banner
    private var headerBanner: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // 标头图标与标题
            HStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(DesignTokens.Colors.accentSubdued)
                        .frame(width: 24, height: 24)

                    Image(systemName: "macwindow")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(L10n.tr("实时预览", "Live Preview"))
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundStyle(DesignTokens.Colors.primaryText)

                        Text("1:1")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.accentSubdued)
                            )
                    }

                    Text(L10n.tr("Finder 菜单效果 • 60fps 同步", "Finder Menu Replica • 60fps Sync"))
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                }
            }

            Spacer()

            // 同步就绪胶囊指示器
            HStack(spacing: 5) {
                Circle()
                    .fill(DesignTokens.Colors.statusGreen)
                    .frame(width: 6, height: 6)

                Text(L10n.tr("已同步", "Synced"))
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(DesignTokens.Colors.subtleFill)
            )
            .overlay(
                Capsule()
                    .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.cardBackground.opacity(0.35))
    }

    // MARK: - Simulated Menu Container
    private var simulatedMenuContainer: some View {
        ZStack(alignment: .topTrailing) {
            // 主模拟菜单体
            VStack(alignment: .leading, spacing: 0) {
                if coordinator.canvasItems.isEmpty {
                    SimulatedMenuEmptyRow()
                } else {
                    ForEach(coordinator.canvasItems) { item in
                        switch item {
                        case .action(let actionId):
                            SimulatedActionItemRow(
                                actionId: actionId,
                                coordinator: coordinator,
                                isHovered: hoveredItemId == item.id
                            )
                            .onHover { hovering in
                                withAnimation(DesignTokens.AnimationToken.quickSpring) {
                                    if hovering {
                                        hoveredItemId = item.id
                                        hoveredSubmenuId = nil
                                    } else if hoveredItemId == item.id {
                                        hoveredItemId = nil
                                    }
                                }
                            }

                        case .separator:
                            SimulatedMenuSeparatorRow()

                        case .submenu(_, let title, let actionIds):
                            SimulatedSubmenuItemRow(
                                title: title,
                                actionIds: actionIds,
                                coordinator: coordinator,
                                isHovered: hoveredItemId == item.id || hoveredSubmenuId == item.id
                            )
                            .onHover { hovering in
                                withAnimation(DesignTokens.AnimationToken.quickSpring) {
                                    if hovering {
                                        hoveredItemId = item.id
                                        hoveredSubmenuId = item.id
                                    } else if hoveredItemId == item.id {
                                        hoveredItemId = nil
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .frame(width: Self.menuWidth)
            .background(
                ZStack {
                    VisualEffectView(
                        material: .popover,
                        blendingMode: .behindWindow,
                        state: .active
                    )
                    Color(nsColor: .windowBackgroundColor).opacity(0.85)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: DesignTokens.Stroke.hairline)
            )
            // 原生 macOS 深度多层投影 (Realistic Drop Shadow)
            .shadow(color: Color.black.opacity(0.20), radius: 16, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

            // 悬停二级子菜单浮层预览 (Nested Submenu Flyout Preview)
            if let activeSubmenuId = hoveredSubmenuId,
               let submenuItem = coordinator.canvasItems.first(where: { $0.id == activeSubmenuId }),
               case .submenu(_, let title, let actionIds) = submenuItem {
                nestedSubmenuFlyout(title: title, actionIds: actionIds)
                    .offset(x: Self.menuWidth - 10, y: calculateSubmenuOffset(for: activeSubmenuId))
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topLeading)))
            }
        }
        .animation(DesignTokens.AnimationToken.quickSpring, value: coordinator.canvasItems)
    }

    // MARK: - Nested Submenu Flyout
    private func nestedSubmenuFlyout(title: String, actionIds: [String]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if actionIds.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 13))
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                    Text("空子菜单")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                }
                .padding(.horizontal, 8)
                .frame(height: Self.rowHeight)
            } else {
                ForEach(actionIds, id: \.self) { actionId in
                    SimulatedActionItemRow(
                        actionId: actionId,
                        coordinator: coordinator,
                        isHovered: hoveredItemId == "nested:\(actionId)"
                    )
                    .onHover { hovering in
                        withAnimation(DesignTokens.AnimationToken.quickSpring) {
                            if hovering {
                                hoveredItemId = "nested:\(actionId)"
                            } else if hoveredItemId == "nested:\(actionId)" {
                                hoveredItemId = nil
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .frame(width: Self.menuWidth - 16)
        .background(
            ZStack {
                VisualEffectView(
                    material: .popover,
                    blendingMode: .behindWindow,
                    state: .active
                )
                Color(nsColor: .windowBackgroundColor).opacity(0.88)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: DesignTokens.Stroke.hairline)
        )
        .shadow(color: Color.black.opacity(0.24), radius: 16, x: 2, y: 8)
        .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)
    }

    private func calculateSubmenuOffset(for submenuId: String) -> CGFloat {
        var runningOffset: CGFloat = 4 // container top padding
        for item in coordinator.canvasItems {
            if item.id == submenuId {
                return runningOffset
            }
            switch item {
            case .action, .submenu:
                runningOffset += Self.rowHeight
            case .separator:
                runningOffset += 9 // separator height + vertical padding
            }
        }
        return runningOffset
    }

    // MARK: - Footer Hint Bar
    private var footerHintBar: some View {
        HStack {
            Image(systemName: "cursorarrow.motionlines")
                .font(.system(size: 11))
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

            Text(L10n.tr("悬停可交互体验选中高亮与二级子菜单展开", "Hover to experience highlight and submenu expansion"))
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

            Spacer()

            Text(L10n.tr("macOS 1:1 像素拟真", "macOS 1:1 Pixel True"))
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.tertiaryText)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, 6)
        .background(DesignTokens.Colors.cardBackground.opacity(0.3))
    }
}

// MARK: - Simulated Action Item Row
/// 拟真 NSMenuItem 行组件
/// 严格匹配 macOS 系统菜单：16x16 层次感 SF Symbol、13pt 系统字体、快捷键右对齐、4pt 圆角高亮胶囊。
@MainActor
public struct SimulatedActionItemRow: View {
    public let actionId: String
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    public let isHovered: Bool

    public init(
        actionId: String,
        coordinator: AppMenuStateCoordinator,
        isHovered: Bool = false
    ) {
        self.actionId = actionId
        self.coordinator = coordinator
        self.isHovered = isHovered
    }

    private var action: MenuAction? {
        coordinator.action(for: actionId)
    }

    private var title: String {
        action?.localizedTitle ?? actionId
    }

    private var iconName: String {
        action?.iconName ?? "gearshape"
    }

    private var shortcutText: String? {
        MenuShortcutMapper.shortcut(for: actionId)
    }

    public var body: some View {
        HStack(spacing: 8) {
            // A. 16x16 monochrome / hierarchical 图标
            Image(systemName: iconName)
                .font(.system(size: 12, weight: .regular))
                .symbolRenderingMode(isHovered ? .monochrome : .hierarchical)
                .foregroundStyle(isHovered ? Color.white : DesignTokens.Colors.primaryText)
                .frame(width: 16, height: 16, alignment: .center)

            // B. 动作标题
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(isHovered ? Color.white : DesignTokens.Colors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            // C. 键盘快捷键提示 (如 ⌥⌘C, ⌃⌥T 等)
            if let shortcut = shortcutText {
                Text(shortcut)
                    .font(DesignTokens.Typography.monospacedSmall)
                    .foregroundStyle(isHovered ? Color.white.opacity(0.85) : DesignTokens.Colors.tertiaryText)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: LiveMenuMockupView.rowHeight)
        .background(
            RoundedRectangle(cornerRadius: LiveMenuMockupView.highlightRadius, style: .continuous)
                .fill(isHovered ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Simulated Menu Separator Row
/// 拟真 NSMenuItem.separator() 分隔线组件
/// 严格匹配系统 1pt 细线与纵向留白比例。
public struct SimulatedMenuSeparatorRow: View {
    public init() {}

    public var body: some View {
        Rectangle()
            .fill(DesignTokens.Colors.separator.opacity(0.65))
            .frame(height: 1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
    }
}

// MARK: - Simulated Submenu Item Row
/// 拟真二级子菜单项行组件
/// 显示标题、动作计数胶囊以及系统右向展开箭头 (chevron.right)。
@MainActor
public struct SimulatedSubmenuItemRow: View {
    public let title: String
    public let actionIds: [String]
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    public let isHovered: Bool

    public init(
        title: String,
        actionIds: [String],
        coordinator: AppMenuStateCoordinator,
        isHovered: Bool = false
    ) {
        self.title = title
        self.actionIds = actionIds
        self.coordinator = coordinator
        self.isHovered = isHovered
    }

    public var body: some View {
        HStack(spacing: 8) {
            // A. 图标
            Image(systemName: "folder")
                .font(.system(size: 12, weight: .regular))
                .symbolRenderingMode(isHovered ? .monochrome : .hierarchical)
                .foregroundStyle(isHovered ? Color.white : DesignTokens.Colors.primaryText)
                .frame(width: 16, height: 16, alignment: .center)

            // B. 子菜单标题
            Text(title.isEmpty ? "未命名子菜单" : title)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(isHovered ? Color.white : DesignTokens.Colors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            // C. 动作数提示
            if !actionIds.isEmpty {
                Text("\(actionIds.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isHovered ? Color.white.opacity(0.75) : DesignTokens.Colors.tertiaryText)
            }

            // D. macOS 标准子菜单展开角标
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(isHovered ? Color.white : DesignTokens.Colors.tertiaryText)
        }
        .padding(.horizontal, 6)
        .frame(height: LiveMenuMockupView.rowHeight)
        .background(
            RoundedRectangle(cornerRadius: LiveMenuMockupView.highlightRadius, style: .continuous)
                .fill(isHovered ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Simulated Menu Empty Row
/// 空态行组件：当画布未编排任何项目时展示
public struct SimulatedMenuEmptyRow: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "ellipsis.rectangle")
                .font(.system(size: 13))
                .foregroundStyle(DesignTokens.Colors.tertiaryText)
                .frame(width: 16, height: 16)

            Text("（暂无菜单项）")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(height: LiveMenuMockupView.rowHeight)
    }
}

// MARK: - Canvas Grid Pattern
/// 背景微细点阵纹理，增强空间纵深质感
private struct CanvasGridPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 20
                let cols = Int(geometry.size.width / spacing) + 1
                let rows = Int(geometry.size.height / spacing) + 1

                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        path.addEllipse(in: CGRect(x: x, y: y, width: 1.5, height: 1.5))
                    }
                }
            }
            .fill(DesignTokens.Colors.primaryText)
        }
    }
}
