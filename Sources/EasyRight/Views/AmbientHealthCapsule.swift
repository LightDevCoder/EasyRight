import SwiftUI
import AppKit
import FinderSync

/// Ambient health status capsule for the Studio header and navigation bar.
/// Summarizes real-time system status (Full Disk Access, FinderSync registration, Heartbeat)
/// with a live pulsating indicator and micro-interaction states.
public struct AmbientHealthCapsule: View {
    public let onTap: () -> Void

    @State private var snapshot: RightClickMenuHealthSnapshot?
    @State private var isHovering: Bool = false
    @State private var isPulsing: Bool = false

    private let timer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()

    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Status indicator dot (with pulsing glow when healthy)
                ZStack {
                    if currentHealthLevel == .healthy {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isPulsing ? 1.4 : 1.0)
                            .opacity(isPulsing ? 0.3 : 0.7)
                    }

                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                        .shadow(color: statusColor.opacity(0.6), radius: 3, x: 0, y: 0)
                }
                .frame(width: 10, height: 10)

                // Summary status text
                Text(statusTitle)
                    .font(DesignTokens.Typography.captionMedium)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                // Disclosure indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(DesignTokens.Colors.tertiaryText)
            }
            .padding(.horizontal, DesignTokens.Spacing.capsulePaddingHorizontal)
            .padding(.vertical, DesignTokens.Spacing.capsulePaddingVertical)
            .background(
                Capsule()
                    .fill(
                        isHovering
                            ? statusBackgroundColor.opacity(1.35)
                            : statusBackgroundColor
                    )
            )
            .overlay(
                Capsule()
                    .stroke(statusBorderColor, lineWidth: DesignTokens.Stroke.hairline)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignTokens.AnimationToken.quickSpring) {
                isHovering = hovering
            }
        }
        .help(tooltipText)
        .onAppear {
            refreshHealth()
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .onReceive(timer) { _ in
            refreshHealth()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            refreshHealth()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: SystemReloader.configChangedNotification)) { _ in
            refreshHealth()
        }
    }

    // MARK: - Status Computations

    private var currentHealthLevel: RightClickMenuHealthLevel {
        snapshot?.healthLevel ?? .healthy
    }

    private var statusTitle: String {
        guard let snapshot else { return "检测中…" }

        switch snapshot.healthLevel {
        case .healthy:
            return "正常"
        case .warning:
            if snapshot.fullDiskAccessState == .denied {
                return "需要授权"
            }
            return "需要关注"
        case .critical:
            return "扩展异常"
        }
    }

    private var statusColor: Color {
        guard let snapshot else { return DesignTokens.Colors.statusGreen }

        switch snapshot.healthLevel {
        case .healthy:
            return DesignTokens.Colors.statusGreen
        case .warning:
            return DesignTokens.Colors.statusAmber
        case .critical:
            return DesignTokens.Colors.statusRed
        }
    }

    private var statusBackgroundColor: Color {
        guard let snapshot else { return DesignTokens.Colors.statusGreenBackground }

        switch snapshot.healthLevel {
        case .healthy:
            return DesignTokens.Colors.statusGreenBackground
        case .warning:
            return DesignTokens.Colors.statusAmberBackground
        case .critical:
            return DesignTokens.Colors.statusRedBackground
        }
    }

    private var statusBorderColor: Color {
        guard let snapshot else { return DesignTokens.Colors.statusGreenBorder }

        switch snapshot.healthLevel {
        case .healthy:
            return DesignTokens.Colors.statusGreenBorder
        case .warning:
            return DesignTokens.Colors.statusAmberBorder
        case .critical:
            return DesignTokens.Colors.statusRedBorder
        }
    }

    private var tooltipText: String {
        guard let snapshot else { return "正在检测系统健康状态…" }

        switch snapshot.healthLevel {
        case .healthy:
            let count = snapshot.observedPathCount
            return count > 0
                ? "系统扩展与权限运行正常，已监听 \(count) 个路径（点击查看详细诊断）"
                : "系统扩展与权限运行正常（点击查看详细诊断）"
        case .warning:
            if snapshot.fullDiskAccessState == .denied {
                return "完全磁盘访问未授权，部分受保护文件操作可能受限（点击查看诊断）"
            }
            return "系统状态需要关注（点击查看诊断与修复建议）"
        case .critical:
            return "访达右键扩展未启用或未注册（点击打开一键自愈修复）"
        }
    }

    // MARK: - Asynchronous Refresh

    private func refreshHealth() {
        let isFinderSyncEnabled = FIFinderSyncController.isExtensionEnabled
        DispatchQueue.global(qos: .userInitiated).async {
            let nextSnapshot = makeRightClickMenuHealthSnapshot(
                finderSyncControllerEnabled: isFinderSyncEnabled
            )
            DispatchQueue.main.async {
                self.snapshot = nextSnapshot
            }
        }
    }
}
