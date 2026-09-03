import SwiftUI
import AppKit
import FinderSync

// MARK: - Notification Extension
public extension Notification.Name {
    /// 触发打开新手引导模态弹窗的通知
    static let showOnboarding = Notification.Name("com.easyright.app.showOnboarding")
}

// MARK: - Starter Presets Enum
/// 开箱即用的精心调优新手起始预设方案
public enum StarterPreset: String, CaseIterable, Identifiable, Sendable {
    /// 极简日常：文本、Word、剪切、复制路径、系统终端
    case minimalist = "minimalist"
    /// 开发者特供：系统终端、VS Code、Unix 路径、Git 路径、Markdown、JSON、哈希计算、隐藏文件切换
    case developer = "developer"
    /// 全能全景：完整功能矩阵，分类分组并配以清晰原生分隔符
    case powerUser = "powerUser"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .minimalist: return "极简日常"
        case .developer: return "开发者特供"
        case .powerUser: return "全能全景"
        }
    }

    public var subtitle: String {
        switch self {
        case .minimalist: return "轻量纯粹 · 高频日常必备"
        case .developer: return "研发利器 · 终端与工程扩展"
        case .powerUser: return "全域覆盖 · 矩阵式完整套件"
        }
    }

    public var description: String {
        switch self {
        case .minimalist:
            return "保留文本与 Office 新建、快速剪切、路径复制及系统终端等 5 项核心动作，清爽干净。"
        case .developer:
            return "专为工程师定制，涵盖终端、VS Code、Shell/Git 路径、Markdown/JSON 及哈希校验与隐藏文件。"
        case .powerUser:
            return "全功能矩阵，涵盖文档创作、文件流转、代码调试、图像转换及二维码工具，以清晰分隔符归类。"
        }
    }

    public var iconName: String {
        switch self {
        case .minimalist: return "sparkles"
        case .developer: return "chevron.left.forwardslash.chevron.right"
        case .powerUser: return "wand.and.stars"
        }
    }

    public var tag: String {
        switch self {
        case .minimalist: return "推荐日常"
        case .developer: return "推荐开发"
        case .powerUser: return "全量套件"
        }
    }

    /// 预设包含的动作总数
    public var actionCount: Int {
        canvasItems().filter { $0.isAction }.count
    }

    /// 预设包含的分隔符总数
    public var separatorCount: Int {
        canvasItems().filter { $0.isSeparator }.count
    }

    /// 预设展示的高亮要点
    public var previewHighlights: [String] {
        switch self {
        case .minimalist:
            return [
                "新建 TXT / Word 文档",
                "快速剪切与路径复制",
                "一键呼出系统终端"
            ]
        case .developer:
            return [
                "Terminal & VS Code 唤起",
                "Unix 安全路径 & Git 相对路径",
                "MD5 / SHA256 & 隐藏文件切换"
            ]
        case .powerUser:
            return [
                "全套 Office / 文本 / 表格新建",
                "剪切 / 粘贴 / 永久删除 / 移动",
                "图像快速转码 & 文本生成二维码"
            ]
        }
    }

    /// 转换为画布菜单排布项目
    public func canvasItems() -> [MenuCanvasItem] {
        switch self {
        case .minimalist:
            return [
                .action(actionId: "easyright.action.newfile.txt"),
                .action(actionId: "easyright.action.newfile.docx"),
                .separator(),
                .action(actionId: "easyright.action.filemanage.cut"),
                .action(actionId: "easyright.action.filemanage.copyPath"),
                .separator(),
                .action(actionId: "easyright.action.terminal.terminal")
            ]
        case .developer:
            return [
                .action(actionId: "easyright.action.terminal.terminal"),
                .action(actionId: "easyright.action.terminal.vscode"),
                .separator(),
                .action(actionId: "easyright.action.pathcopy.shellEscaped"),
                .action(actionId: "easyright.action.pathcopy.gitRelative"),
                .action(actionId: "easyright.action.filemanage.copyPath"),
                .separator(),
                .action(actionId: "easyright.action.newfile.md"),
                .action(actionId: "easyright.action.newfile.json"),
                .separator(),
                .action(actionId: "easyright.action.utility.calculateSHA256"),
                .action(actionId: "easyright.action.utility.calculateMD5"),
                .action(actionId: "easyright.action.utility.toggleHiddenFiles")
            ]
        case .powerUser:
            return [
                .action(actionId: "easyright.action.newfile.txt"),
                .action(actionId: "easyright.action.newfile.md"),
                .action(actionId: "easyright.action.newfile.docx"),
                .action(actionId: "easyright.action.newfile.xlsx"),
                .separator(),
                .action(actionId: "easyright.action.filemanage.cut"),
                .action(actionId: "easyright.action.filemanage.paste"),
                .action(actionId: "easyright.action.filemanage.copyPath"),
                .action(actionId: "easyright.action.pathcopy.shellEscaped"),
                .separator(),
                .action(actionId: "easyright.action.terminal.terminal"),
                .action(actionId: "easyright.action.terminal.vscode"),
                .separator(),
                .action(actionId: "easyright.action.utility.toggleHiddenFiles"),
                .action(actionId: "easyright.action.utility.calculateSHA256"),
                .action(actionId: "easyright.action.utility.textToQRCode"),
                .action(actionId: "easyright.action.utility.convertToPNG")
            ]
        }
    }
}

// MARK: - Onboarding Step Enum
public enum OnboardingStep: Int, CaseIterable, Identifiable, Sendable {
    case welcome = 0
    case permissions = 1
    case preset = 2

    public var id: Int { rawValue }

    public var stepTitle: String {
        switch self {
        case .welcome: return "欢迎使用"
        case .permissions: return "系统授权"
        case .preset: return "选择预设"
        }
    }

    public var stepSubtitle: String {
        switch self {
        case .welcome: return "探索 Raycast 风格现代右键增强"
        case .permissions: return "检查并授予必要系统运行权限"
        case .preset: return "挑选最适合您工作流的起始布局"
        }
    }

    public var iconName: String {
        switch self {
        case .welcome: return "sparkles"
        case .permissions: return "lock.shield"
        case .preset: return "square.grid.2x2"
        }
    }
}

// MARK: - Main Onboarding Modal View (640 × 480 pt)
/// 3 步开箱即用新手引导弹窗，提供特性速览、实时权限轮询与起始预设装配。
@MainActor
public struct OnboardingView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    @Binding public var isPresented: Bool
    public var onComplete: (() -> Void)?

    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedPreset: StarterPreset = .developer
    @State private var isFullDiskAccessGranted: Bool = false
    @State private var isFinderExtensionEnabled: Bool = false
    @State private var isCheckingPermissions: Bool = false

    private let pollingTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    @MainActor
    public init(
        coordinator: AppMenuStateCoordinator,
        isPresented: Binding<Bool>,
        onComplete: (() -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self._isPresented = isPresented
        self.onComplete = onComplete
    }

    @MainActor
    public init(
        isPresented: Binding<Bool>,
        onComplete: (() -> Void)? = nil
    ) {
        self.coordinator = .shared
        self._isPresented = isPresented
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            // 1. Acrylic Vibrancy Background
            VisualEffectView(
                material: .underWindowBackground,
                blendingMode: .behindWindow,
                state: .active
            )
            .ignoresSafeArea()

            // 2. Structured 3-Step Container
            VStack(spacing: 0) {
                // Top Header with Step Tabs
                topHeaderView
                    .frame(height: 52)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .background(DesignTokens.Colors.cardBackground.opacity(0.40))

                Divider()
                    .overlay(DesignTokens.Stroke.defaultBorder)

                // Step Content Area (Smooth Animated Switching)
                ZStack {
                    switch currentStep {
                    case .welcome:
                        WelcomeStepView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    case .permissions:
                        PermissionsStepView(
                            isFullDiskAccessGranted: isFullDiskAccessGranted,
                            isFinderExtensionEnabled: isFinderExtensionEnabled,
                            isChecking: isCheckingPermissions,
                            onOpenFDA: openFullDiskAccessSettings,
                            onOpenExtension: openExtensionSettings,
                            onRefresh: checkPermissionsState
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                    case .preset:
                        PresetSelectionStepView(selectedPreset: $selectedPreset)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(DesignTokens.AnimationToken.standardSpring, value: currentStep)

                Divider()
                    .overlay(DesignTokens.Stroke.defaultBorder)

                // Bottom Navigation Control Bar
                bottomNavigationBar
                    .frame(height: 56)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .background(DesignTokens.Colors.cardBackground.opacity(0.50))
            }
        }
        .frame(width: 640, height: 480)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.window, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.window, style: .continuous)
                .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
        )
        .onAppear {
            checkPermissionsState()
        }
        .onReceive(pollingTimer) { _ in
            if currentStep == .permissions {
                checkPermissionsState()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            checkPermissionsState()
        }
    }

    // MARK: - Top Header View
    private var topHeaderView: some View {
        HStack {
            // App Icon & Brand
            HStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 22, height: 22)

                    Image(systemName: "cursorarrow.rays")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("EasyRight · 新手引导")
                    .font(DesignTokens.Typography.windowTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)
            }

            Spacer()

            // Step Indicator Pills
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(OnboardingStep.allCases) { step in
                    let isCurrent = currentStep == step
                    let isCompleted = currentStep.rawValue > step.rawValue

                    Button {
                        withAnimation(DesignTokens.AnimationToken.standardSpring) {
                            currentStep = step
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                            } else {
                                Text("\(step.rawValue + 1)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }

                            Text(step.stepTitle)
                                .font(DesignTokens.Typography.captionMedium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .foregroundStyle(
                            isCurrent
                                ? Color.accentColor
                                : (isCompleted ? DesignTokens.Colors.primaryText : DesignTokens.Colors.tertiaryText)
                        )
                        .background(
                            Capsule()
                                .fill(
                                    isCurrent
                                        ? DesignTokens.Colors.accentSubdued
                                        : (isCompleted ? DesignTokens.Colors.subtleFill : Color.clear)
                                )
                        )
                    }
                    .buttonStyle(.plain)

                    if step.rawValue < OnboardingStep.allCases.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(DesignTokens.Colors.quaternaryText)
                    }
                }
            }
        }
    }

    // MARK: - Bottom Navigation Bar
    private var bottomNavigationBar: some View {
        HStack {
            // Back Button
            if currentStep.rawValue > 0 {
                Button {
                    withAnimation(DesignTokens.AnimationToken.standardSpring) {
                        if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                            currentStep = prev
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("上一步")
                            .font(DesignTokens.Typography.bodyMedium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .foregroundStyle(DesignTokens.Colors.primaryText)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(DesignTokens.Colors.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Spacer()
                    .frame(width: 70)
            }

            Spacer()

            // Step Progress Dots
            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases) { step in
                    Capsule()
                        .fill(currentStep == step ? Color.accentColor : DesignTokens.Colors.tertiaryText.opacity(0.35))
                        .frame(width: currentStep == step ? 20 : 6, height: 6)
                        .animation(DesignTokens.AnimationToken.standardSpring, value: currentStep)
                }
            }

            Spacer()

            // Next or Finish Button
            if currentStep != .preset {
                Button {
                    withAnimation(DesignTokens.AnimationToken.standardSpring) {
                        if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                            currentStep = next
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("下一步")
                            .font(DesignTokens.Typography.bodyMedium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(Color.accentColor)
                    )
                    .shadow(color: Color.accentColor.opacity(0.30), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    completeOnboarding()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("开始使用")
                            .font(DesignTokens.Typography.bodyMedium)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Permissions & Actions
    private func checkPermissionsState() {
        isCheckingPermissions = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fda = FullDiskAccessChecker.hasFullDiskAccess()
            let status = FinderExtensionDiagnostics.checkStatus()
            let extEnabled = (status == .enabled) || FIFinderSyncController.isExtensionEnabled

            DispatchQueue.main.async {
                self.isFullDiskAccessGranted = fda
                self.isFinderExtensionEnabled = extEnabled
                self.isCheckingPermissions = false
            }
        }
    }

    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openExtensionSettings() {
        if #available(macOS 13.0, *),
           let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
        } else {
            FIFinderSyncController.showExtensionManagementInterface()
        }
    }

    private func completeOnboarding() {
        let items = selectedPreset.canvasItems()
        coordinator.canvasItems = items
        _ = SharedStorageManager.shared.saveCanvasItems(items, postNotification: true)
        SharedStorageManager.shared.setBool(true, forKey: SharedStorageManager.Keys.hasCompletedOnboarding)
        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
        SystemReloader.postConfigChanged()
        onComplete?()
        isPresented = false
    }
}

// MARK: - Step 1: Welcome Showcase View
private struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer(minLength: 4)

            // Hero Brand Icon & Title
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.accentSubdued)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.accentColor.opacity(0.20), radius: 10, x: 0, y: 4)

                    Image(systemName: "cursorarrow.rays")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 4) {
                    Text("欢迎使用开源EasyRight")
                        .font(DesignTokens.Typography.headerTitle)
                        .foregroundStyle(DesignTokens.Colors.primaryText)

                    Text("全新 Raycast 极简设计 · 自由拖拽画布 · 毫秒级原生体验")
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.secondaryText)
                }
            }

            // 3 Feature Showcase Cards
            HStack(spacing: DesignTokens.Spacing.md) {
                featureCard(
                    icon: "sparkles",
                    iconColor: Color.accentColor,
                    title: "现代原生质感",
                    desc: "深度适配 macOS 毛玻璃亚克力、精准阴影与微动效，无缝融入系统体验。"
                )

                featureCard(
                    icon: "square.grid.2x2",
                    iconColor: Color.blue,
                    title: "自由画布编排",
                    desc: "拖拽排序、原生分隔符插入与 1:1 实时原生菜单预览，随心定制专属右键。"
                )

                featureCard(
                    icon: "shield.lefthalf.filled",
                    iconColor: Color.green,
                    title: "本地隐私安全",
                    desc: "纯本地离线执行，零数据上传、零云端遥测与极低资源消耗。"
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Spacer(minLength: 4)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    private func featureCard(icon: String, iconColor: Color, title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Text(desc)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
}

// MARK: - Step 2: Permissions Step View
private struct PermissionsStepView: View {
    let isFullDiskAccessGranted: Bool
    let isFinderExtensionEnabled: Bool
    let isChecking: Bool
    let onOpenFDA: () -> Void
    let onOpenExtension: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Header
            VStack(spacing: 4) {
                Text("系统权限配置")
                    .font(DesignTokens.Typography.headerTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Text("右键菜单与深度文件操作依赖以下系统权限，授权后将自动检测生效：")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
            }
            .padding(.top, DesignTokens.Spacing.xs)

            // Permissions Rows
            VStack(spacing: DesignTokens.Spacing.sm) {
                permissionCard(
                    icon: "internaldrive",
                    title: "完全磁盘访问权限 (Full Disk Access)",
                    description: "允许在访达任意受保护目录（桌面、下载、文档等）创建文件、批量剪切及计算哈希。",
                    isApproved: isFullDiskAccessGranted,
                    actionTitle: "授权全盘访问",
                    action: onOpenFDA
                )

                permissionCard(
                    icon: "puzzlepiece.extension",
                    title: "访达扩展同步服务 (FinderSync Extension)",
                    description: "系统原生 FinderSync 扩展，负责在访达右键上下文菜单中实时呈现动作项与图标。",
                    isApproved: isFinderExtensionEnabled,
                    actionTitle: "启用访达扩展",
                    action: onOpenExtension
                )
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)

            // Live Polling & Summary Bar
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isFullDiskAccessGranted && isFinderExtensionEnabled {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(DesignTokens.Colors.statusGreen)
                        .font(.system(size: 13))

                    Text("所有必要系统权限均已就绪，可直接进入下一步选择预设")
                        .font(DesignTokens.Typography.captionMedium)
                        .foregroundStyle(DesignTokens.Colors.statusGreen)
                } else {
                    if isChecking {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Circle()
                            .fill(DesignTokens.Colors.statusAmber)
                            .frame(width: 8, height: 8)
                    }

                    Text("正在自动轮询系统权限状态，在系统设置中授权后将即刻识别…")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.secondaryText)

                    Spacer()

                    Button("手动刷新", action: onRefresh)
                        .font(DesignTokens.Typography.captionMedium)
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.xs)

            Spacer(minLength: 4)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    private func permissionCard(
        icon: String,
        title: String,
        description: String,
        isApproved: Bool,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isApproved ? DesignTokens.Colors.statusGreenBackground : DesignTokens.Colors.statusAmberBackground)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isApproved ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusAmber)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(DesignTokens.Typography.cardTitle)
                        .foregroundStyle(DesignTokens.Colors.primaryText)

                    statusBadge(isApproved: isApproved)
                }

                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            if isApproved {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text("已就绪")
                        .font(DesignTokens.Typography.captionMedium)
                }
                .foregroundStyle(DesignTokens.Colors.statusGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(DesignTokens.Colors.statusGreenBackground)
                )
            } else {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                            .font(DesignTokens.Typography.captionMedium)
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 10))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(Color.accentColor)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .stroke(
                    isApproved ? DesignTokens.Stroke.defaultBorder : DesignTokens.Colors.statusAmberBorder,
                    lineWidth: DesignTokens.Stroke.hairline
                )
        )
    }

    private func statusBadge(isApproved: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: isApproved ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 9))
            Text(isApproved ? "已授权" : "未授权")
                .font(DesignTokens.Typography.caption2)
        }
        .foregroundStyle(isApproved ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusAmber)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(isApproved ? DesignTokens.Colors.statusGreenBackground : DesignTokens.Colors.statusAmberBackground)
        )
    }
}

// MARK: - Step 3: Preset Selection Step View
private struct PresetSelectionStepView: View {
    @Binding var selectedPreset: StarterPreset

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Header
            VStack(spacing: 4) {
                Text("选择起始菜单预设")
                    .font(DesignTokens.Typography.headerTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Text("挑选适合您日常工作流的初始菜单排布，稍后可在动作画布中随时自由增删与拖拽重排：")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
            }
            .padding(.top, DesignTokens.Spacing.xs)

            // 3 Preset Cards
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(StarterPreset.allCases) { preset in
                    StarterPresetCardView(
                        preset: preset,
                        isSelected: selectedPreset == preset
                    ) {
                        withAnimation(DesignTokens.AnimationToken.standardSpring) {
                            selectedPreset = preset
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Spacer(minLength: 4)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

// MARK: - Starter Preset Card View
private struct StarterPresetCardView: View {
    let preset: StarterPreset
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                // Top Row: Tag & Selection Radio
                HStack {
                    Text(preset.tag)
                        .font(DesignTokens.Typography.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? Color.accentColor : DesignTokens.Colors.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? DesignTokens.Colors.accentSubdued : DesignTokens.Colors.subtleFill)
                        )

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.accentColor : DesignTokens.Colors.tertiaryText)
                }

                // Preset Icon & Title
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: preset.iconName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSelected ? Color.accentColor : DesignTokens.Colors.primaryText)

                    Text(preset.title)
                        .font(DesignTokens.Typography.cardTitle)
                        .foregroundStyle(DesignTokens.Colors.primaryText)
                }

                Text(preset.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(DesignTokens.Stroke.defaultBorder)

                // Item Counts Badge
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 10))
                    Text("\(preset.actionCount) 项动作 · \(preset.separatorCount) 组分隔")
                        .font(DesignTokens.Typography.caption2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(DesignTokens.Colors.tertiaryText)

                // Highlight Points
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(preset.previewHighlights, id: \.self) { highlight in
                        HStack(alignment: .top, spacing: 4) {
                            Text("•")
                                .font(DesignTokens.Typography.caption2)
                                .foregroundStyle(isSelected ? Color.accentColor : DesignTokens.Colors.tertiaryText)
                            Text(highlight)
                                .font(DesignTokens.Typography.caption2)
                                .foregroundStyle(DesignTokens.Colors.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.cardPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                    .fill(isSelected ? DesignTokens.Colors.cardBackgroundSelected : DesignTokens.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                    .stroke(
                        isSelected ? Color.accentColor : DesignTokens.Stroke.defaultBorder,
                        lineWidth: isSelected ? 1.5 : DesignTokens.Stroke.hairline
                    )
            )
            .shadow(
                color: isSelected ? Color.accentColor.opacity(0.15) : Color.clear,
                radius: 6,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
    }
}
