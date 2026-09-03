import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 自定义外部应用管理视图 (CustomAppsSettingsView)
/// 允许用户自主选取 macOS 本地安装的任意 .app（如 Keka、Typora、IINA 等），
/// 自定义右键菜单名称、图标、启用状态与生效过滤条件（文件/目录/指定后缀）。
@MainActor
public struct CustomAppsSettingsView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    @State private var editingAction: CustomAppAction? = nil
    @State private var showEditSheet: Bool = false

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
            headerBar
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.vertical, DesignTokens.Spacing.lg)
                .background(DesignTokens.Colors.cardBackground.opacity(0.4))

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            if coordinator.customAppActions.isEmpty {
                emptyStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                appsListView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
        .sheet(item: $editingAction) { item in
            CustomAppEditSheet(action: item) { updated in
                coordinator.updateCustomAppAction(updated)
            }
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                    Text("自定义应用动作")
                        .font(.system(size: 16, weight: .bold))
                }
                Text("将系统安装的任意软件（如 Keka 压缩解压、各类编辑器与播放器）添加至访达右键菜单")
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
            }

            Spacer()

            Button {
                pickAndAddApp()
            } label: {
                Label("添加本地应用", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    // MARK: - Apps List
    private var appsListView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(coordinator.customAppActions) { appAction in
                    appCardRow(for: appAction)
                }
            }
            .padding(DesignTokens.Spacing.xl)
        }
    }

    // MARK: - App Card Row
    private func appCardRow(for appAction: CustomAppAction) -> some View {
        let isInstalled = InstalledAppRegistry.shared.isInstalled(appAction.bundleIdentifier)
            || FileManager.default.fileExists(atPath: appAction.appPath)

        return HStack(spacing: DesignTokens.Spacing.md) {
            // App 图标
            Group {
                if FileManager.default.fileExists(atPath: appAction.appPath) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: appAction.appPath))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 28))
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                }
            }
            .frame(width: 36, height: 36)

            // App 信息
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text(appAction.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(appAction.isEnabled ? DesignTokens.Colors.primaryText : DesignTokens.Colors.secondaryText)

                    if !isInstalled {
                        Text("未在系统中找到")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text(appAction.bundleIdentifier)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(DesignTokens.Colors.secondaryText)

                    Text("•")
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)

                    Text(appAction.targetFilter.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer()

            // 编辑规则按钮
            Button {
                editingAction = appAction
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)
            .help("修改规则与名称")

            // 删除按钮
            Button(role: .destructive) {
                withAnimation(DesignTokens.AnimationToken.quickSpring) {
                    coordinator.removeCustomAppAction(id: appAction.id)
                }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)
            .help("移除此应用动作")

            // 启用开关
            Toggle("", isOn: Binding(
                get: { appAction.isEnabled },
                set: { enabled in
                    var updated = appAction
                    updated.isEnabled = enabled
                    coordinator.updateCustomAppAction(updated)
                }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
        )
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "plus.rectangle.on.rectangle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("暂无自定义应用动作")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Text("你可以添加 Keka、Typora、IINA、Sublime Merge 等任意本地 App，\n右键即可直接将选中的文件或目录传递给目标应用。")
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
                    .frame(maxWidth: 380)
            }

            Button {
                pickAndAddApp()
            } label: {
                Label("从 /Applications 选取应用", systemImage: "plus")
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(DesignTokens.Spacing.xxl)
    }

    // MARK: - Pick .app Bundle
    private func pickAndAddApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = "添加"
        panel.message = "请选择需要添加至右键菜单的 macOS 应用程序 (.app)"

        if panel.runModal() == .OK, let selectedURL = panel.url {
            if let customAction = CustomAppAction.fromAppBundle(url: selectedURL) {
                // 如果是 Keka，智能预设友好标题和扩展名过滤
                var configured = customAction
                if customAction.bundleIdentifier.lowercased().contains("keka") {
                    configured.name = "使用 Keka 压缩/解压"
                }
                coordinator.addCustomAppAction(configured)
            }
        }
    }
}

/// 自定义应用配置编辑弹窗
private struct CustomAppEditSheet: View {
    @State var action: CustomAppAction
    var onSave: (CustomAppAction) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var filterMode: Int = 0
    @State private var customExtsText: String = ""

    init(action: CustomAppAction, onSave: @escaping (CustomAppAction) -> Void) {
        self._action = State(initialValue: action)
        self.onSave = onSave

        switch action.targetFilter {
        case .all:
            self._filterMode = State(initialValue: 0)
            self._customExtsText = State(initialValue: "")
        case .directoriesOnly:
            self._filterMode = State(initialValue: 1)
            self._customExtsText = State(initialValue: "")
        case .filesOnly:
            self._filterMode = State(initialValue: 2)
            self._customExtsText = State(initialValue: "")
        case .extensions(let exts):
            self._filterMode = State(initialValue: 3)
            self._customExtsText = State(initialValue: exts.joined(separator: ", "))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("编辑应用右键动作")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button("完成") {
                    saveAndDismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(DesignTokens.Spacing.lg)

            Divider()

            Form {
                Section("显示设置") {
                    TextField("右键菜单标题", text: $action.name)
                    LabeledContent("应用路径", value: action.appPath)
                    LabeledContent("Bundle ID", value: action.bundleIdentifier)
                }

                Section("触发条件") {
                    Picker("生效对象", selection: $filterMode) {
                        Text("全部文件与文件夹").tag(0)
                        Text("仅文件夹").tag(1)
                        Text("仅文件").tag(2)
                        Text("指定文件扩展名").tag(3)
                    }
                    .pickerStyle(.radioGroup)

                    if filterMode == 3 {
                        TextField("扩展名列表（逗号分隔）", text: $customExtsText)
                        Text("示例：zip, 7z, rar, tar, gz（无需输入前导点）")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                Button("保存更改") {
                    saveAndDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(DesignTokens.Spacing.md)
        }
        .frame(width: 480, height: 420)
    }

    private func saveAndDismiss() {
        var updated = action
        switch filterMode {
        case 0:
            updated.targetFilter = .all
        case 1:
            updated.targetFilter = .directoriesOnly
        case 2:
            updated.targetFilter = .filesOnly
        case 3:
            let parsed = customExtsText
                .components(separatedBy: CharacterSet(charactersIn: ",; "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
            updated.targetFilter = .extensions(parsed)
        default:
            updated.targetFilter = .all
        }
        onSave(updated)
        dismiss()
    }
}
