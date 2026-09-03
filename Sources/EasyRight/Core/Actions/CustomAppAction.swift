import Foundation
import AppKit

/// 自定义应用动作生效目标筛选规则
public enum CustomAppTargetFilter: Codable, Equatable, Sendable {
    /// 所有文件和文件夹
    case all
    /// 仅文件夹/目录
    case directoriesOnly
    /// 仅普通文件（排除文件夹）
    case filesOnly
    /// 仅特定文件扩展名（不区分大小写，如 ["zip", "7z", "rar"]）
    case extensions([String])

    public var displayName: String {
        switch self {
        case .all:
            return "全部文件与文件夹"
        case .directoriesOnly:
            return "仅文件夹"
        case .filesOnly:
            return "仅文件"
        case .extensions(let exts):
            return "指定扩展名 (\(exts.joined(separator: ", ")))"
        }
    }
}

/// 用户自定义添加的外部应用动作实体
public struct CustomAppAction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var bundleIdentifier: String
    public var appPath: String
    public var targetFilter: CustomAppTargetFilter
    public var isEnabled: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        appPath: String,
        targetFilter: CustomAppTargetFilter = .all,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.appPath = appPath
        self.targetFilter = targetFilter
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    /// 从本地 .app Bundle 路径构造默认的 CustomAppAction
    public static func fromAppBundle(url: URL) -> CustomAppAction? {
        guard let bundle = Bundle(url: url),
              let bundleId = bundle.bundleIdentifier else {
            return nil
        }
        let appName = (bundle.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (bundle.infoDictionary?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        return CustomAppAction(
            name: "在 \(appName) 中打开",
            bundleIdentifier: bundleId,
            appPath: url.path,
            targetFilter: .all,
            isEnabled: true
        )
    }
}

/// 包装 CustomAppAction 为系统统一的 MenuAction
public final class CustomAppOpenAction: MenuAction, @unchecked Sendable {
    public let customApp: CustomAppAction

    public var actionId: String {
        "easyright.action.customapp.\(customApp.id.uuidString)"
    }

    public var localizedTitle: String {
        customApp.name
    }

    public var iconName: String? {
        "arrow.up.forward.app"
    }

    public var category: ActionCategory {
        .terminal
    }

    public var associatedBundleIdentifier: String? {
        customApp.bundleIdentifier
    }

    public var tier: ActionTier {
        .professional
    }

    public var isEnabledByDefault: Bool {
        customApp.isEnabled
    }

    public var requiresExistingTargets: Bool {
        true
    }

    public var isHighRisk: Bool {
        false
    }

    public var riskDescription: String? {
        nil
    }

    public var settingsGroup: SettingsActionGroup {
        .standard
    }

    public init(customApp: CustomAppAction) {
        self.customApp = customApp
    }

    public func isAvailable(for targetURLs: [URL]) -> Bool {
        return isAvailable(for: targetURLs, isContainer: false)
    }

    public func isAvailable(for targetURLs: [URL], isContainer: Bool) -> Bool {
        guard customApp.isEnabled else { return false }

        // 检查 App 是否仍安装在系统上
        let isInstalled = InstalledAppRegistry.shared.isInstalled(customApp.bundleIdentifier)
            || FileManager.default.fileExists(atPath: customApp.appPath)
        guard isInstalled else { return false }

        // 空白背景容器
        if isContainer {
            switch customApp.targetFilter {
            case .all, .directoriesOnly:
                return true
            case .filesOnly, .extensions:
                return false
            }
        }

        guard !targetURLs.isEmpty else { return false }

        switch customApp.targetFilter {
        case .all:
            return true
        case .directoriesOnly:
            return targetURLs.allSatisfy { url in
                var isDir: ObjCBool = false
                return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
            }
        case .filesOnly:
            return targetURLs.allSatisfy { url in
                var isDir: ObjCBool = false
                return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue
            }
        case .extensions(let allowedExts):
            let normalized = Set(allowedExts.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")).lowercased() })
            guard !normalized.isEmpty else { return true }
            return targetURLs.allSatisfy { url in
                let ext = url.pathExtension.lowercased()
                return normalized.contains(ext)
            }
        }
    }

    public func execute(targetURLs: [URL]) -> Bool {
        return submit(targetURLs: targetURLs, completion: { _ in }) == .accepted
    }

    public func submit(
        targetURLs: [URL],
        completion: @escaping @Sendable (ActionCompletionStatus) -> Void
    ) -> ActionSubmission {
        guard !targetURLs.isEmpty else {
            completion(.failed)
            return .rejected
        }

        let resolvedAppURL: URL? = {
            if let url = InstalledAppRegistry.shared.url(for: customApp.bundleIdentifier) {
                return url
            }
            let fileURL = URL(fileURLWithPath: customApp.appPath)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
            return nil
        }()

        guard let appURL = resolvedAppURL else {
            AppLog.error("找不到目标应用: \(self.customApp.name) [\(self.customApp.bundleIdentifier)]", category: .action)
            SharedHUDManager.show(
                title: "无法打开",
                content: "未在系统中找到应用：\(customApp.name)",
                isSuccess: false
            )
            completion(.failed)
            return .rejected
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.promptsUserIfNeeded = true

        NSWorkspace.shared.open(targetURLs, withApplicationAt: appURL, configuration: configuration) { _, error in
            if let error = error {
                AppLog.error("拉起应用 [\(self.customApp.name)] 失败: \(error.localizedDescription)", category: .action)
                SharedHUDManager.show(
                    title: "拉起失败",
                    content: "无法启动 \(self.customApp.name): \(error.localizedDescription)",
                    isSuccess: false
                )
                completion(.failed)
            } else {
                SharedHUDManager.show(
                    title: "已打开",
                    content: "已在 \(self.customApp.name) 中打开选中项目",
                    isSuccess: true
                )
                completion(.succeeded)
            }
        }

        return .accepted
    }
}
