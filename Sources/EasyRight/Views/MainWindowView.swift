import SwiftUI
import AppKit

/// Sections available in the Studio Main Window
public enum StudioSection: String, CaseIterable, Identifiable {
    case canvas = "canvas"
    case customApps = "customApps"
    case settings = "settings"
    case diagnostics = "diagnostics"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .canvas: return L10n.tr("动作画布", "Action Canvas")
        case .customApps: return L10n.tr("自定义应用", "Custom Apps")
        case .settings: return L10n.tr("偏好设置", "Preferences")
        case .diagnostics: return L10n.tr("系统诊断", "Diagnostics")
        }
    }

    public var iconName: String {
        switch self {
        case .canvas: return "square.grid.2x2"
        case .customApps: return "arrow.up.forward.app"
        case .settings: return "gearshape"
        case .diagnostics: return "waveform.path.ecg"
        }
    }
}

/// Convenience alias mapping GeneralSettingsView to OverviewSettingsView
typealias GeneralSettingsView = OverviewSettingsView

/// The primary Studio window shell for EasyRight, implementing Raycast-style
/// acrylic vibrancy, a compact unified top toolbar, and dynamic section switching.
@MainActor
public struct MainWindowView: View {
    @AppStorage("has_completed_onboarding") private var hasCompletedOnboarding: Bool = false
    @ObservedObject private var languageManager = AppLanguageManager.shared
    @StateObject private var coordinator: AppMenuStateCoordinator
    @State private var selectedSection: StudioSection = .canvas
    @State private var isStatusDrawerPresented: Bool = false
    @State private var showOnboardingSheet: Bool = false
    @State private var showPresetSheet: Bool = false

    @MainActor
    public init(initialSection: StudioSection = .canvas, showOnboarding: Bool = false) {
        _selectedSection = State(initialValue: initialSection)
        _coordinator = StateObject(wrappedValue: .shared)
        _showOnboardingSheet = State(initialValue: showOnboarding)
    }

    @MainActor
    public init(coordinator: AppMenuStateCoordinator, initialSection: StudioSection = .canvas, showOnboarding: Bool = false) {
        _coordinator = StateObject(wrappedValue: coordinator)
        _selectedSection = State(initialValue: initialSection)
        _showOnboardingSheet = State(initialValue: showOnboarding)
    }

    public var body: some View {
        ZStack {
            // 1. Acrylic Translucent Background
            VisualEffectView(
                material: .underWindowBackground,
                blendingMode: .behindWindow,
                state: .active
            )
            .ignoresSafeArea()

            // 2. Main Window Content Layout
            VStack(spacing: 0) {
                // Unified Compact Top Toolbar
                topToolbar
                    .frame(height: DesignTokens.Layout.toolbarHeight)
                    .padding(.horizontal, DesignTokens.Spacing.toolbarHorizontal)
                    .background(DesignTokens.Colors.cardBackground.opacity(0.35))

                Divider()
                    .overlay(DesignTokens.Stroke.defaultBorder)

                // Section Content Container
                ZStack {
                    switch selectedSection {
                    case .canvas:
                        CanvasMainView(coordinator: coordinator)
                            .transition(.opacity.combined(with: .scale(scale: 0.99)))
                    case .customApps:
                        CustomAppsSettingsView(coordinator: coordinator)
                            .transition(.opacity.combined(with: .scale(scale: 0.99)))
                    case .settings:
                        GeneralSettingsView()
                            .transition(.opacity.combined(with: .scale(scale: 0.99)))
                    case .diagnostics:
                        DiagnosticsSettingsView()
                            .transition(.opacity.combined(with: .scale(scale: 0.99)))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(DesignTokens.AnimationToken.standardSpring, value: selectedSection)
            }

            // 3. Slide-out Diagnostic Drawer Overlay
            if isStatusDrawerPresented {
                Color.black.opacity(0.20)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(DesignTokens.AnimationToken.quickSpring) {
                            isStatusDrawerPresented = false
                        }
                    }

                HStack(spacing: 0) {
                    Spacer()
                    DiagnosticDrawerView(isPresented: $isStatusDrawerPresented)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                .ignoresSafeArea()
            }
        }
        .animation(DesignTokens.AnimationToken.quickSpring, value: isStatusDrawerPresented)
        .frame(
            minWidth: DesignTokens.Layout.windowMinWidth,
            idealWidth: DesignTokens.Layout.windowIdealWidth,
            minHeight: DesignTokens.Layout.windowMinHeight,
            idealHeight: DesignTokens.Layout.windowIdealHeight
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.window, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.window, style: .continuous)
                .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
        )
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView(coordinator: coordinator, isPresented: $showOnboardingSheet)
        }
        .sheet(isPresented: $showPresetSheet) {
            PresetSelectionSheet(coordinator: coordinator, isPresented: $showPresetSheet)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboardingSheet = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showOnboarding)) { _ in
            showOnboardingSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPresetSelection)) { _ in
            showPresetSheet = true
        }
        .id(languageManager.language)
    }

    // MARK: - Top Toolbar
    private var topToolbar: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // A. App Branding & Title
            appBranding

            Spacer()

            // B. Center Section Switcher
            sectionRouterSegment

            Spacer()

            // C. Ambient Health Status Capsule
            AmbientHealthCapsule {
                withAnimation(DesignTokens.AnimationToken.quickSpring) {
                    isStatusDrawerPresented.toggle()
                }
            }
        }
    }

    // MARK: - App Branding
    private var appBranding: some View {
        Button {
            showPresetSheet = true
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)

                    Image(systemName: "cursorarrow.rays")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text("EasyRight")
                            .font(DesignTokens.Typography.windowTitle)
                            .foregroundStyle(DesignTokens.Colors.primaryText)

                        Text("Studio")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(DesignTokens.Colors.tertiaryText)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.subtleFill)
                            )
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(L10n.tr("点击切换菜单预设方案", "Click to switch menu preset"))
    }

    // MARK: - Section Router Segment
    private var sectionRouterSegment: some View {
        HStack(spacing: 2) {
            ForEach(StudioSection.allCases) { section in
                let isSelected = selectedSection == section
                Button {
                    withAnimation(DesignTokens.AnimationToken.standardSpring) {
                        selectedSection = section
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: section.iconName)
                            .font(.system(size: DesignTokens.Icon.small))
                            .symbolRenderingMode(.hierarchical)

                        Text(section.title)
                            .font(DesignTokens.Typography.bodyMedium)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(
                        isSelected ? DesignTokens.Colors.primaryText : DesignTokens.Colors.secondaryText
                    )
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .fill(isSelected ? DesignTokens.Colors.cardBackground : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                                    .stroke(
                                        isSelected ? DesignTokens.Stroke.defaultBorder : Color.clear,
                                        lineWidth: DesignTokens.Stroke.hairline
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.panel, style: .continuous)
                .fill(DesignTokens.Colors.subtleFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.panel, style: .continuous)
                .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
        )
    }
}

// MARK: - Canvas Multi-Pane Main View (Issue 04, 05, 07)
@MainActor
public struct CanvasMainView: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    @State private var activeRightTab: RightSideTab = .preview

    public enum RightSideTab {
        case preview
        case inspector
    }

    @MainActor
    public init(coordinator: AppMenuStateCoordinator) {
        self.coordinator = coordinator
    }

    @MainActor
    public init() {
        self.coordinator = .shared
    }

    public var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width >= 1220
            HStack(spacing: 0) {
                // 1. 左侧动作资源库 (Action Library)
                ActionLibraryView(coordinator: coordinator)

                Divider()
                    .overlay(DesignTokens.Stroke.defaultBorder)

                // 2. 中间已编排菜单画布 (Active Menu Staging Canvas)
                ActiveMenuCanvasView(coordinator: coordinator)
                    .frame(minWidth: DesignTokens.Layout.canvasMinWidth, maxWidth: .infinity, maxHeight: .infinity)

                // 3. 右侧辅助区域 (自适应模式：超宽屏双栏并列；标准窗口下智能单栏平滑切换)
                if isWide {
                    if coordinator.isLivePreviewPresented {
                        Divider()
                            .overlay(DesignTokens.Stroke.defaultBorder)

                        LiveMenuMockupView(coordinator: coordinator)
                            .frame(width: DesignTokens.Layout.livePreviewWidth)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }

                    if coordinator.selectedActionId != nil {
                        Divider()
                            .overlay(DesignTokens.Stroke.defaultBorder)

                        ActionInspectorView(coordinator: coordinator)
                            .frame(width: DesignTokens.Layout.inspectorWidth)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                } else {
                    if hasRightPane {
                        Divider()
                            .overlay(DesignTokens.Stroke.defaultBorder)

                        rightAdaptiveSidebar
                            .frame(width: DesignTokens.Layout.inspectorWidth)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            }
            .onChange(of: coordinator.selectedActionId) { newId in
                if newId != nil {
                    activeRightTab = .inspector
                }
            }
        }
        .animation(DesignTokens.springTransition, value: coordinator.isLivePreviewPresented)
        .animation(DesignTokens.springTransition, value: coordinator.selectedActionId)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var hasRightPane: Bool {
        coordinator.isLivePreviewPresented || coordinator.selectedActionId != nil
    }

    private var rightAdaptiveSidebar: some View {
        VStack(spacing: 0) {
            // 当实时预览与动作详情同时可用时，提供紧凑分段控制器
            if coordinator.isLivePreviewPresented && coordinator.selectedActionId != nil {
                HStack(spacing: 4) {
                    Button {
                        withAnimation(DesignTokens.AnimationToken.quickSpring) {
                            activeRightTab = .preview
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "macwindow")
                                .font(.system(size: 10))
                            Text("1:1 预览")
                                .font(DesignTokens.Typography.captionMedium)
                                .lineLimit(1)
                                .fixedSize()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                                .fill(activeRightTab == .preview ? DesignTokens.Colors.accentSubdued : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(activeRightTab == .preview ? Color.accentColor : DesignTokens.Colors.secondaryText)

                    Button {
                        withAnimation(DesignTokens.AnimationToken.quickSpring) {
                            activeRightTab = .inspector
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 10))
                            Text("动作详情")
                                .font(DesignTokens.Typography.captionMedium)
                                .lineLimit(1)
                                .fixedSize()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                                .fill(activeRightTab == .inspector ? DesignTokens.Colors.accentSubdued : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(activeRightTab == .inspector ? Color.accentColor : DesignTokens.Colors.secondaryText)

                    Spacer()

                    Button {
                        withAnimation(DesignTokens.AnimationToken.quickSpring) {
                            if activeRightTab == .inspector {
                                coordinator.selectedActionId = nil
                                activeRightTab = .preview
                            } else {
                                coordinator.isLivePreviewPresented = false
                            }
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DesignTokens.Colors.tertiaryText)
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .help("收起右侧面板")
                }
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, 4)
                .background(DesignTokens.Colors.cardBackground.opacity(0.3))

                Divider()
                    .overlay(DesignTokens.Stroke.defaultBorder)
            }

            if activeRightTab == .inspector && coordinator.selectedActionId != nil {
                ActionInspectorView(coordinator: coordinator)
            } else if coordinator.isLivePreviewPresented {
                LiveMenuMockupView(coordinator: coordinator)
            } else if coordinator.selectedActionId != nil {
                ActionInspectorView(coordinator: coordinator)
            }
        }
    }
}

// MARK: - Canvas Placeholder View (Staging for Issues 04, 05, 06, 07)
public struct CanvasPlaceholderView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.accentSubdued)
                        .frame(width: 64, height: 64)

                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("动作画布与实时预览")
                        .font(DesignTokens.Typography.headerTitle)
                        .foregroundStyle(DesignTokens.Colors.primaryText)

                    Text("自由拖拽排序右键动作、自定义系统分隔符、并在右侧 1:1 实时预览 macOS 菜单呈现")
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 440)
                }
            }

            // Feature preview cards
            HStack(spacing: DesignTokens.Spacing.md) {
                featureCard(
                    icon: "list.bullet.rectangle",
                    title: "动作资源库",
                    desc: "分类检索系统、文件、终端与实用工具"
                )

                featureCard(
                    icon: "arrow.up.and.down.and.arrow.left.and.right",
                    title: "自由编排",
                    desc: "可视化拖拽重排与原生分隔符插入"
                )

                featureCard(
                    icon: "macwindow",
                    title: "1:1 原生预览",
                    desc: "60fps 动态模拟真实 Finder 菜单呈现"
                )
            }
            .frame(maxWidth: 620)

            Spacer()
        }
        .padding(DesignTokens.Spacing.windowPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func featureCard(icon: String, title: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: DesignTokens.Icon.medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Text(desc)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
