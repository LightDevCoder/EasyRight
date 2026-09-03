import SwiftUI
import AppKit

/// 分类筛选胶囊数据模型
private struct CategoryChipItem: Identifiable, Hashable {
    let category: ActionCategory?
    var id: String { category?.rawValue ?? "all" }

    var title: String {
        category?.localizedName ?? "全部"
    }

    var iconName: String {
        switch category {
        case nil: return "square.grid.2x2"
        case .newFile: return "doc.badge.plus"
        case .fileManage: return "folder"
        case .terminal: return "terminal"
        case .utility: return "wrench.and.screwdriver"
        }
    }
}

/// 动作资源库视图 (ActionLibraryView)
/// 作为主画布左侧面板，提供全量内置动作的实时检索、分类筛选、即时上架切换与拖拽源输出。
@MainActor
public struct ActionLibraryView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator

    private let categoryChips: [CategoryChipItem] = [
        CategoryChipItem(category: nil),
        CategoryChipItem(category: .newFile),
        CategoryChipItem(category: .fileManage),
        CategoryChipItem(category: .terminal),
        CategoryChipItem(category: .utility)
    ]

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
            // 1. 顶部搜索栏与分类芯片
            VStack(spacing: DesignTokens.Spacing.xs) {
                searchBar
                    .padding(.top, DesignTokens.Spacing.sm)
                    .padding(.horizontal, DesignTokens.Spacing.sm)

                categoryFilterChips
                    .padding(.bottom, DesignTokens.Spacing.xs)
            }
            .background(DesignTokens.Colors.cardBackground.opacity(0.4))

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 2. 动作列表滚动容器
            ZStack {
                if coordinator.filteredActions.isEmpty {
                    emptySearchResultsView
                } else {
                    actionScrollView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 3. 底部状态摘要
            bottomSummaryBar
        }
        .frame(
            minWidth: DesignTokens.Layout.libraryMinWidth,
            idealWidth: DesignTokens.Layout.libraryIdealWidth,
            maxWidth: DesignTokens.Layout.libraryMaxWidth
        )
        .background(DesignTokens.Colors.controlBackground.opacity(0.3))
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: DesignTokens.Icon.small))
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

            TextField("搜索动作...", text: $coordinator.searchQuery)
                .textFieldStyle(.plain)
                .font(DesignTokens.Typography.body)

            if !coordinator.searchQuery.isEmpty {
                Button {
                    coordinator.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: DesignTokens.Icon.small))
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                }
                .buttonStyle(.plain)
                .help("清除搜索词")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .fill(DesignTokens.Colors.subtleFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
        )
    }

    // MARK: - Category Filter Chips
    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(categoryChips) { chip in
                    let isSelected = coordinator.selectedCategory == chip.category
                    Button {
                        withAnimation(DesignTokens.AnimationToken.quickSpring) {
                            coordinator.selectedCategory = chip.category
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: chip.iconName)
                                .font(.system(size: 11))
                                .symbolRenderingMode(.hierarchical)

                            Text(chip.title)
                                .font(DesignTokens.Typography.captionMedium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(
                            isSelected ? DesignTokens.Colors.primaryText : DesignTokens.Colors.secondaryText
                        )
                        .background(
                            Capsule()
                                .fill(isSelected ? DesignTokens.Colors.cardBackground : DesignTokens.Colors.subtleFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    isSelected ? DesignTokens.Stroke.prominentBorder : DesignTokens.Stroke.defaultBorder,
                                    lineWidth: DesignTokens.Stroke.hairline
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, 2)
        }
    }

    // MARK: - Action Scroll View
    private var actionScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(coordinator.filteredActions, id: \.actionId) { action in
                    ActionLibraryRowView(
                        coordinator: coordinator,
                        action: action
                    )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, DesignTokens.Spacing.xs)
        }
    }

    // MARK: - Empty State View
    private var emptySearchResultsView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

            VStack(spacing: 2) {
                Text("未找到相关动作")
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)

                Text("尝试更换搜索词或选择“全部”分类")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
            }

            if !coordinator.searchQuery.isEmpty || coordinator.selectedCategory != nil {
                Button {
                    withAnimation(DesignTokens.AnimationToken.standardSpring) {
                        coordinator.searchQuery = ""
                        coordinator.selectedCategory = nil
                    }
                } label: {
                    Text("重置筛选")
                        .font(DesignTokens.Typography.captionMedium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.subtleFill)
                        )
                        .overlay(
                            Capsule()
                                .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
    }

    // MARK: - Bottom Summary Bar
    private var bottomSummaryBar: some View {
        HStack {
            Text("共 \(coordinator.allActions.count) 个动作")
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

            Spacer()

            Text("已上架 \(coordinator.stagedActionCount) 项")
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.secondaryText)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, 6)
        .background(DesignTokens.Colors.cardBackground.opacity(0.3))
    }
}

// MARK: - Action Library Row View
@MainActor
public struct ActionLibraryRowView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    public let action: MenuAction

    @State private var isHovered: Bool = false

    public init(coordinator: AppMenuStateCoordinator, action: MenuAction) {
        self.coordinator = coordinator
        self.action = action
    }

    private var isSelected: Bool {
        coordinator.selectedActionId == action.actionId
    }

    private var isStaged: Bool {
        coordinator.isActionStaged(actionId: action.actionId)
    }

    public var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // A. SF 符号图标 (Hierarchical Monochrome Shading)
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        isSelected
                            ? Color.accentColor.opacity(0.18)
                            : DesignTokens.Colors.subtleFill
                    )
                    .frame(width: 26, height: 26)

                Image(systemName: action.iconName ?? "command")
                    .font(.system(size: DesignTokens.Icon.standard))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        isSelected ? Color.accentColor : DesignTokens.Colors.primaryText
                    )
            }

            // B. 动作标题与分类/元数据徽章
            VStack(alignment: .leading, spacing: 1) {
                Text(action.localizedTitle)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundStyle(DesignTokens.Colors.primaryText)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(action.category.localizedName)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)

                    if action.isHighRisk {
                        Text("高风险")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(DesignTokens.Colors.statusAmber)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 0.5)
                            .background(
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(DesignTokens.Colors.statusAmberBackground)
                            )
                    }
                }
            }

            Spacer()

            // C. 上架状态徽章 / 快速添加与移除切换按钮
            toggleButton
        }
        .padding(.horizontal, 8)
        .frame(height: DesignTokens.Layout.standardRowHeight)
        .frame(minHeight: DesignTokens.Layout.minRowHeight, maxHeight: DesignTokens.Layout.maxRowHeight)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .fill(
                    isSelected
                        ? DesignTokens.Colors.cardBackgroundSelected
                        : (isHovered ? DesignTokens.Colors.cardBackgroundHover : Color.clear)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                .stroke(
                    isSelected ? DesignTokens.Stroke.prominentBorder : Color.clear,
                    lineWidth: DesignTokens.Stroke.hairline
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            coordinator.selectedActionId = action.actionId
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrag {
            NSItemProvider(object: action.actionId as NSString)
        }
    }

    // MARK: - Toggle Button
    private var toggleButton: some View {
        Button {
            withAnimation(DesignTokens.AnimationToken.quickSpring) {
                coordinator.toggleAction(actionId: action.actionId)
            }
        } label: {
            ZStack {
                if isStaged {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.accentColor)
                } else {
                    Image(systemName: isHovered ? "plus.circle.fill" : "plus.circle")
                        .font(.system(size: 15))
                        .foregroundStyle(
                            isHovered ? Color.accentColor : DesignTokens.Colors.tertiaryText
                        )
                }
            }
            .frame(width: 22, height: 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isStaged ? "点击从菜单中移除" : "点击添加到菜单")
    }
}
