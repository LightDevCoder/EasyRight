import SwiftUI

/// 独立的预设方案切换面板，供左上角标题与偏好设置直接唤起
@MainActor
public struct PresetSelectionSheet: View {
    @ObservedObject public var coordinator: AppMenuStateCoordinator
    @Binding public var isPresented: Bool
    @State private var selectedPreset: StarterPreset = .developer

    public init(coordinator: AppMenuStateCoordinator, isPresented: Binding<Bool>) {
        self.coordinator = coordinator
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 顶栏关闭与标题
            HStack {
                Text(L10n.tr("切换菜单预设方案", "Switch Menu Preset"))
                    .font(DesignTokens.Typography.headerTitle)
                    .foregroundStyle(DesignTokens.Colors.primaryText)

                Spacer()

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DesignTokens.Colors.tertiaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.sm)

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 预设卡片选择区域（复用向导第 3 步的卡片排版）
            PresetSelectionStepView(selectedPreset: $selectedPreset)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.md)

            Divider()
                .overlay(DesignTokens.Stroke.defaultBorder)

            // 底栏操作区
            HStack {
                Button(L10n.tr("取消", "Cancel")) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    coordinator.applyPreset(selectedPreset)
                    SharedHUDManager.show(
                        title: L10n.tr("预设已应用", "Preset Applied"),
                        content: L10n.tr("已切换为「\(selectedPreset.title)」方案", "Switched to '\(selectedPreset.title)' layout"),
                        isSuccess: true
                    )
                    isPresented = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text(L10n.tr("应用此预设", "Apply Preset"))
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.controlBackground.opacity(0.4))
        }
        .frame(width: 820, height: 490)
        .background(
            VisualEffectView(
                material: .underWindowBackground,
                blendingMode: .behindWindow,
                state: .active
            )
        )
    }
}
