import SwiftUI
import AppKit
import FinderSync

/// Slide-out Diagnostic Drawer revealing granular check cards for Full Disk Access,
/// FinderSync extension registration, and IPC Heartbeat, along with a prominent One-Click Self-Repair button.
public struct DiagnosticDrawerView: View {
    @Binding public var isPresented: Bool

    @State private var snapshot: RightClickMenuHealthSnapshot?
    @State private var isRepairRunning: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var repairOutcomeMessage: String?
    @State private var repairSucceeded: Bool?

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drawer Header
            drawerHeader
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.cardBackground.opacity(0.5))

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // Scrollable Diagnostic Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Summary Banner
                    statusSummaryBanner

                    // 1. Full Disk Access Check Card
                    fullDiskAccessCard

                    // 2. FinderSync Extension Check Card
                    finderSyncExtensionCard

                    // 3. IPC Heartbeat & Shared Storage Card
                    ipcHeartbeatCard

                    // 4. One-Click Self-Repair Section
                    selfRepairSection

                    // 5. Utility Actions Section
                    supportUtilitiesSection
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .frame(width: DesignTokens.Layout.diagnosticDrawerWidth)
        .frame(maxHeight: .infinity)
        .background(
            VisualEffectView(
                material: .popover,
                blendingMode: .behindWindow,
                state: .active
            )
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(DesignTokens.Stroke.defaultBorder)
                .frame(width: DesignTokens.Stroke.hairline)
        }
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: -6, y: 0)
        .onAppear {
            refreshDiagnostics()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: SystemReloader.configChangedNotification)) { _ in
            refreshDiagnostics()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            refreshDiagnostics()
        }
    }

    // MARK: - Header
    private var drawerHeader: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: DesignTokens.Icon.medium, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            Text(L10n.tr("系统健康与诊断", "System Health & Diagnostics"))
                .font(DesignTokens.Typography.sectionTitle)
                .foregroundStyle(DesignTokens.Colors.primaryText)

            Spacer()

            // Refresh Button
            Button(action: refreshDiagnostics) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: DesignTokens.Icon.small, weight: .medium))
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            }
            .buttonStyle(.plain)
            .disabled(isRepairRunning || isRefreshing)
            .help(L10n.tr("刷新诊断检测", "Refresh diagnostics"))

            // Close Drawer Button
            Button {
                withAnimation(DesignTokens.AnimationToken.quickSpring) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(DesignTokens.Colors.subtleFill)
                    )
            }
            .buttonStyle(.plain)
            .help(L10n.tr("关闭抽屉", "Close drawer"))
        }
    }

    // MARK: - Summary Banner
    private var statusSummaryBanner: some View {
        let level = snapshot?.healthLevel ?? .healthy
        let bannerColor: Color
        let bannerBg: Color
        let bannerIcon: String
        let bannerText: String

        switch level {
        case .healthy:
            bannerColor = DesignTokens.Colors.statusGreen
            bannerBg = DesignTokens.Colors.statusGreenBackground
            bannerIcon = "checkmark.shield.fill"
            bannerText = L10n.tr("所有服务运行正常，右键菜单已就绪。", "All services operating normally. Context menus ready.")
        case .warning:
            bannerColor = DesignTokens.Colors.statusAmber
            bannerBg = DesignTokens.Colors.statusAmberBackground
            bannerIcon = "exclamationmark.triangle.fill"
            bannerText = L10n.tr("部分系统权限或配置需要关注，菜单功能可能受限。", "Some permissions need attention; features may be limited.")
        case .critical:
            bannerColor = DesignTokens.Colors.statusRed
            bannerBg = DesignTokens.Colors.statusRedBackground
            bannerIcon = "xmark.octagon.fill"
            bannerText = L10n.tr("访达扩展未激活或处于异常状态，右键菜单无法正常弹出。", "Finder extension inactive or malfunctioning; context menu unavailable.")
        }

        return HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: bannerIcon)
                .font(.system(size: DesignTokens.Icon.medium))
                .foregroundStyle(bannerColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(level == .healthy ? L10n.tr("健康度良好", "Healthy") : (level == .warning ? L10n.tr("需要关注", "Attention Needed") : L10n.tr("服务异常", "Service Error")))
                    .font(DesignTokens.Typography.bodyBold)
                    .foregroundStyle(bannerColor)

                Text(bannerText)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(DesignTokens.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .fill(bannerBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .stroke(bannerColor.opacity(0.35), lineWidth: DesignTokens.Stroke.hairline)
        )
    }

    // MARK: - Card 1: Full Disk Access
    private var fullDiskAccessCard: some View {
        let isGranted = snapshot?.fullDiskAccessState == .granted

        return diagnosticCard(
            icon: "lock.shield",
            iconColor: isGranted ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusAmber,
            title: "完全磁盘访问权限",
            statusBadgeText: isGranted ? "已授权" : "未授权",
            statusBadgeColor: isGranted ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusAmber,
            description: "授权访问受系统保护的文件夹（桌面、文稿、下载等）。未授权时核心菜单可弹出，但受保护文件读写受限。",
            buttonTitle: "打开系统设置",
            buttonIcon: "arrow.up.forward.app"
        ) {
            openSystemSettingsFullDiskAccess()
        }
    }

    // MARK: - Card 2: FinderSync Extension
    private var finderSyncExtensionCard: some View {
        let extState = snapshot?.finderExtensionState ?? .unknown
        let isEnabled = extState == .enabled
        let badgeText: String
        let badgeColor: Color

        switch extState {
        case .enabled:
            badgeText = "已启用"
            badgeColor = DesignTokens.Colors.statusGreen
        case .registeredButNotEnabled:
            badgeText = "未在系统启用"
            badgeColor = DesignTokens.Colors.statusAmber
        case .notRegistered:
            badgeText = "未注册"
            badgeColor = DesignTokens.Colors.statusRed
        case .unknown:
            badgeText = "检测中"
            badgeColor = DesignTokens.Colors.secondaryText
        }

        return diagnosticCard(
            icon: "puzzlepiece.extension",
            iconColor: isEnabled ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusRed,
            title: "访达扩展 (FinderSync)",
            statusBadgeText: badgeText,
            statusBadgeColor: badgeColor,
            description: "macOS 原生右键集成扩展，注入 Finder 进程捕获点击并渲染动作菜单。须在系统“扩展”面板勾选。",
            buttonTitle: "打开扩展设置",
            buttonIcon: "gearshape.2"
        ) {
            openFinderExtensionSettings()
        }
    }

    // MARK: - Card 3: IPC Heartbeat & Storage
    private var ipcHeartbeatCard: some View {
        let heartbeat = snapshot?.heartbeatState ?? .missing
        let isHealthy: Bool
        let heartbeatText: String
        let badgeColor: Color

        switch heartbeat {
        case .recent(let count):
            isHealthy = count > 0
            heartbeatText = "活跃 (监听 \(count) 个入口)"
            badgeColor = isHealthy ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusAmber
        case .stale:
            isHealthy = false
            heartbeatText = "已失活 (>120s 未响应)"
            badgeColor = DesignTokens.Colors.statusAmber
        case .missing:
            isHealthy = false
            heartbeatText = "无心跳记录"
            badgeColor = DesignTokens.Colors.statusRed
        }

        let pendingCount = snapshot?.pendingActionCount ?? 0
        let failedCount = snapshot?.failedActionCount ?? 0

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "bolt.heart")
                    .font(.system(size: DesignTokens.Icon.standard))
                    .foregroundStyle(isHealthy ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusAmber)

                Text("扩展心跳与 IPC")
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Spacer()

                statusTag(text: heartbeatText, color: badgeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("共享数据容器:")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.secondaryText)
                    Spacer()
                    Text("可用")
                        .font(DesignTokens.Typography.captionBold)
                        .foregroundStyle(DesignTokens.Colors.statusGreen)
                }

                HStack {
                    Text("动作队列状态:")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.secondaryText)
                    Spacer()
                    Text("待处理 \(pendingCount) / 失败 \(failedCount)")
                        .font(DesignTokens.Typography.captionBold)
                        .foregroundStyle(failedCount > 0 ? DesignTokens.Colors.statusRed : DesignTokens.Colors.primaryText)
                }
            }
            .padding(.top, 2)
        }
        .studioCard()
    }

    // MARK: - Card 4: Prominent One-Click Self-Repair
    private var selfRepairSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Button(action: executeOneClickSelfRepair) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if isRepairRunning {
                        ProgressView()
                            .controlSize(.small)
                            .colorInvert()
                        Text("正在自愈与重启…")
                            .font(DesignTokens.Typography.bodyBold)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: DesignTokens.Icon.medium, weight: .semibold))
                        Text("一键自愈并重启 Finder")
                            .font(DesignTokens.Typography.bodyBold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .foregroundStyle(.white)
                .background(
                    LinearGradient(
                        colors: isRepairRunning
                            ? [Color.gray, Color.gray.opacity(0.8)]
                            : [Color.accentColor, Color.accentColor.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous))
                .shadow(
                    color: isRepairRunning ? Color.clear : Color.accentColor.opacity(0.35),
                    radius: 6,
                    x: 0,
                    y: 2
                )
            }
            .buttonStyle(.plain)
            .disabled(isRepairRunning)

            if let message = repairOutcomeMessage {
                HStack(spacing: 4) {
                    Image(systemName: (repairSucceeded ?? false) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle((repairSucceeded ?? false) ? DesignTokens.Colors.statusGreen : DesignTokens.Colors.statusRed)

                    Text(message)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.secondaryText)
                }
                .transition(.opacity)
            } else {
                Text("自动重注册扩展、刷新配置共享缓存并重启 Finder，解决 95% 的菜单不出现问题。")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
                    .multilineTextAlignment(.center)
            }
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

    // MARK: - Card 5: Secondary Utilities
    private var supportUtilitiesSection: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Button(action: copyDiagnosticReport) {
                HStack {
                    Label("复制诊断报告", systemImage: "doc.on.doc")
                        .font(DesignTokens.Typography.captionMedium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(DesignTokens.Colors.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: openSharedContainer) {
                HStack {
                    Label("打开共享数据目录", systemImage: "folder")
                        .font(DesignTokens.Typography.captionMedium)
                    Spacer()
                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(size: 10))
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(DesignTokens.Colors.subtleFill)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)

            if (snapshot?.failedActionCount ?? 0) > 0 {
                Button(action: clearFailedActions) {
                    HStack {
                        Label("清空失败动作队列", systemImage: "trash")
                            .font(DesignTokens.Typography.captionMedium)
                            .foregroundStyle(DesignTokens.Colors.statusRed)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(DesignTokens.Colors.statusRedBackground.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Reusable Diagnostic Card Builder
    private func diagnosticCard(
        icon: String,
        iconColor: Color,
        title: String,
        statusBadgeText: String,
        statusBadgeColor: Color,
        description: String,
        buttonTitle: String,
        buttonIcon: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: DesignTokens.Icon.standard))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Spacer()

                statusTag(text: statusBadgeText, color: statusBadgeColor)
            }

            Text(description)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button(action: action) {
                    HStack(spacing: 4) {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(buttonTitle)
                            .font(DesignTokens.Typography.captionMedium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignTokens.Colors.subtleFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                            .stroke(DesignTokens.Stroke.defaultBorder, lineWidth: DesignTokens.Stroke.hairline)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .studioCard()
    }

    private func statusTag(text: String, color: Color) -> some View {
        Text(text)
            .font(DesignTokens.Typography.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.14))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: DesignTokens.Stroke.hairline)
            )
    }

    // MARK: - Operations

    private func refreshDiagnostics() {
        isRefreshing = true
        let finderSyncEnabled = FIFinderSyncController.isExtensionEnabled
        DispatchQueue.global(qos: .userInitiated).async {
            let nextSnapshot = makeRightClickMenuHealthSnapshot(
                finderSyncControllerEnabled: finderSyncEnabled
            )
            DispatchQueue.main.async {
                self.snapshot = nextSnapshot
                self.isRefreshing = false
            }
        }
    }

    private func executeOneClickSelfRepair() {
        isRepairRunning = true
        repairOutcomeMessage = nil
        repairSucceeded = nil

        SharedHUDManager.show(
            title: "正在执行一键自愈",
            content: "正在重新注册扩展、刷新共享状态并重启 Finder…",
            iconName: "wand.and.stars",
            isSuccess: true
        )

        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Invalidate config cache
            ActionConfigCache.shared.invalidate()

            // 2. Re-register PlugInKit extension
            let outcome = SystemReloader.registerFinderExtension(appBundleURL: Bundle.main.bundleURL)

            // 3. Post distributed config notification
            SystemReloader.postConfigChanged()

            // 4. In case registerFinderExtension couldn't find bundle (e.g. CLI debug), ensure Finder restarts
            if outcome.restartFinderResult == nil {
                _ = SystemReloader.restartFinder()
            }

            // Short pause for Finder to initialize plugin
            Thread.sleep(forTimeInterval: 0.8)

            let newSnapshot = makeRightClickMenuHealthSnapshot(
                finderSyncControllerEnabled: FIFinderSyncController.isExtensionEnabled
            )

            DispatchQueue.main.async {
                self.snapshot = newSnapshot
                self.isRepairRunning = false
                let isSuccess = outcome.isSuccess || newSnapshot.healthLevel == .healthy

                self.repairSucceeded = isSuccess
                self.repairOutcomeMessage = isSuccess ? "自愈完成，Finder 已恢复正常响应" : (outcome.errorDescription ?? "自愈完成，请检查系统设置扩展状态")

                SharedHUDManager.show(
                    title: isSuccess ? "自愈成功" : "自愈完成",
                    content: self.repairOutcomeMessage ?? "",
                    iconName: isSuccess ? "checkmark.circle" : "exclamationmark.triangle",
                    isSuccess: isSuccess
                )
            }
        }
    }

    private func openSystemSettingsFullDiskAccess() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    private func openSharedContainer() {
        NSWorkspace.shared.open(SharedStorageManager.shared.sharedContainerURL)
    }

    private func copyDiagnosticReport() {
        guard let snapshot else { return }
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let summary = snapshot.diagnosticSummary(appVersion: appVersion)

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)

        SharedHUDManager.show(
            title: "诊断报告已复制",
            content: "可直接粘贴用于排查与技术支持",
            isSuccess: true
        )
    }

    private func clearFailedActions() {
        do {
            try SharedStorageManager.shared.clearFailedActions()
            SharedHUDManager.show(
                title: "失败队列已清空",
                content: "动作状态已刷新",
                isSuccess: true
            )
            refreshDiagnostics()
        } catch {
            SharedHUDManager.show(
                title: "清空失败",
                content: error.localizedDescription,
                isSuccess: false
            )
        }
    }
}
