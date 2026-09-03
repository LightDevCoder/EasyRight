import SwiftUI

struct OverviewSettingsView: View {
    private enum UpdateCheckState {
        case idle
        case checking
        case upToDate
        case available(version: String, releaseURL: URL)
        case failed(message: String)
    }

    @ObservedObject private var languageManager = AppLanguageManager.shared
    @State private var isLaunchEnabled = false
    @State private var isSilentLaunchEnabled = true
    @State private var showsSuccessHUD = true
    @State private var updateCheckState: UpdateCheckState = .idle

    private var launchEnabledBinding: Binding<Bool> {
        Binding(
            get: { isLaunchEnabled },
            set: { newValue in
                let previousValue = isLaunchEnabled
                guard LaunchServiceManager.shared.setEnabled(newValue) else {
                    isLaunchEnabled = LaunchServiceManager.shared.isEnabled
                    SharedHUDManager.show(
                        title: L10n.tr("自启设置失败", "Launch at Login Failed"),
                        content: L10n.tr("请前往系统设置检查登录项权限", "Please check Login Items in System Settings"),
                        isSuccess: false
                    )
                    return
                }
                guard SharedStorageManager.shared.setBool(
                    newValue,
                    forKey: "shouldStartOnLaunch"
                ) else {
                    _ = LaunchServiceManager.shared.setEnabled(previousValue)
                    isLaunchEnabled = LaunchServiceManager.shared.isEnabled
                    showConfigurationSaveFailure(L10n.tr("登录时启动", "Launch at Login"))
                    return
                }
                isLaunchEnabled = newValue
            }
        )
    }

    var body: some View {
        Form {
            Section(L10n.tr("常规", "General")) {
                Picker(L10n.tr("界面语言", "Language"), selection: $languageManager.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)

                Toggle(L10n.tr("登录时启动EasyRight", "Launch EasyRight at Login"), isOn: launchEnabledBinding)

                Toggle(L10n.tr("后台启动时保持静默", "Stay Silent in Background"), isOn: Binding(
                    get: { isSilentLaunchEnabled },
                    set: saveSilentLaunch
                ))
            }

            Section(L10n.tr("预设方案", "Layout Presets")) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr("起始菜单预设", "Starter Menu Presets"))
                            .font(.body)
                        Text(L10n.tr("从极简日常、开发者特供或全能全景中自由挑选菜单排布", "Choose from Minimalist, Developer, or Power User layouts"))
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.secondaryText)
                    }

                    Spacer()

                    Button {
                        NotificationCenter.default.post(name: .showPresetSelection, object: nil)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2")
                            Text(L10n.tr("切换预设…", "Switch Preset…"))
                        }
                    }
                }
            }

            Section(L10n.tr("服务状态", "Service Status")) {
                ExtensionStatusBanner()
            }

            Section(L10n.tr("反馈", "Feedback")) {
                Toggle(L10n.tr("显示成功提示", "Show Success HUD"), isOn: Binding(
                    get: { showsSuccessHUD },
                    set: saveSuccessHUD
                ))
            }

            Section(L10n.tr("关于", "About")) {
                LabeledContent(L10n.tr("版本", "Version")) {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
                LabeledContent(L10n.tr("许可", "License")) {
                    Text("MIT")
                        .foregroundStyle(.secondary)
                }
                LabeledContent(L10n.tr("隐私", "Privacy")) {
                    Text(L10n.tr("无广告 · 无遥测", "No Ads · No Telemetry"))
                        .foregroundStyle(.secondary)
                }
                Button(action: checkForUpdates) {
                    if case .checking = updateCheckState {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text(L10n.tr("正在检查更新", "Checking for Updates…"))
                        }
                    } else {
                        Label(L10n.tr("检查更新", "Check for Updates"), systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isCheckingForUpdates)

                updateStatusView

                Button {
                    NotificationCenter.default.post(name: .showOnboarding, object: nil)
                } label: {
                    Label(L10n.tr("重新运行新手引导…", "Rerun Onboarding Wizard…"), systemImage: "sparkles")
                }

                Button {
                    if let url = URL(string: "https://github.com/easyright/EasyRight") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label(L10n.tr("查看 GitHub 源码", "View GitHub Repository"), systemImage: "arrow.up.right.square")
                }
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            refresh()
        }
    }

    private func refresh() {
        isLaunchEnabled = LaunchServiceManager.shared.isEnabled
        isSilentLaunchEnabled = SharedStorageManager.shared.getBool(
            forKey: LaunchPresentationPolicy.silentLaunchKey,
            defaultValue: true
        )
        showsSuccessHUD = SharedStorageManager.shared.getBool(
            forKey: "enable_success_hud",
            defaultValue: true
        )
    }

    @ViewBuilder
    private var updateStatusView: some View {
        switch updateCheckState {
        case .idle, .checking:
            EmptyView()
        case .upToDate:
            Label(L10n.tr("当前已是最新版本", "EasyRight is up to date"), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .available(let version, let releaseURL):
            HStack {
                Label(L10n.tr("发现新版本 \(version)", "New version \(version) available"), systemImage: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
                Spacer()
                Button {
                    NSWorkspace.shared.open(releaseURL)
                } label: {
                    Label(L10n.tr("查看版本", "View Release"), systemImage: "arrow.up.right.square")
                }
            }
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        }
    }

    private var isCheckingForUpdates: Bool {
        if case .checking = updateCheckState { return true }
        return false
    }

    private func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        updateCheckState = .checking
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "0.0.0"

        Task {
            let result = await AppUpdateChecker().check(currentVersion: currentVersion)
            switch result {
            case .success(.upToDate):
                updateCheckState = .upToDate
            case .success(.updateAvailable(let version, let releaseURL)):
                updateCheckState = .available(version: version, releaseURL: releaseURL)
            case .failure(let failure):
                updateCheckState = .failed(message: updateFailureMessage(failure))
            }
        }
    }

    private func updateFailureMessage(_ failure: UpdateCheckFailure) -> String {
        switch failure {
        case .network:
            return "网络连接失败，请稍后重试"
        case .httpStatus(let status):
            return "更新服务暂不可用（HTTP \(status)）"
        case .invalidResponse:
            return "更新信息格式无效"
        }
    }

    private func saveSilentLaunch(_ enabled: Bool) {
        guard SharedStorageManager.shared.setBool(
            enabled,
            forKey: LaunchPresentationPolicy.silentLaunchKey
        ) else {
            showConfigurationSaveFailure("静默启动")
            return
        }
        isSilentLaunchEnabled = enabled
    }

    private func saveSuccessHUD(_ enabled: Bool) {
        guard SharedStorageManager.shared.setBool(enabled, forKey: "enable_success_hud") else {
            showConfigurationSaveFailure("成功提示")
            return
        }
        showsSuccessHUD = enabled
    }
}
