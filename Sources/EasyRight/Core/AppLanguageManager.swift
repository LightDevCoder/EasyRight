import Foundation
import Combine

/// EasyRight 界面与菜单支持的语言
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case zhHans = "zh-Hans"
    case en = "en"

    public var id: String { rawValue }

    public init?(rawValue: String) {
        switch rawValue {
        case "system": self = .system
        case "zh-Hans", "zhHans", "zh_CN", "zh": self = .zhHans
        case "en", "en_US": self = .en
        default: return nil
        }
    }

    public var displayName: String {
        switch self {
        case .system:
            return L10n.isEnglish ? "System Default" : "跟随系统"
        case .zhHans:
            return "简体中文"
        case .en:
            return "English"
        }
    }
}

public extension Notification.Name {
    /// 语言切换全局通知
    static let languageDidChange = Notification.Name("easyright.languageDidChange")
    /// 唤起预设选择弹窗通知
    static let showPresetSelection = Notification.Name("easyright.showPresetSelection")
}

/// 全局语言状态管理器
@MainActor
public final class AppLanguageManager: ObservableObject {
    public static let shared = AppLanguageManager()

    @Published public var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: SharedStorageManager.Keys.appLanguage)
            _ = SharedStorageManager.shared.setString(language.rawValue, forKey: SharedStorageManager.Keys.appLanguage)
            NotificationCenter.default.post(name: .languageDidChange, object: nil)
            DistributedNotificationCenter.default().postNotificationName(
                Notification.Name("com.easyright.app.configChanged"),
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
        }
    }

    public init() {
        let saved = SharedStorageManager.shared.getString(forKey: SharedStorageManager.Keys.appLanguage)
            ?? UserDefaults.standard.string(forKey: SharedStorageManager.Keys.appLanguage)
            ?? AppLanguage.system.rawValue
        self.language = AppLanguage(rawValue: saved) ?? .system
    }

    public var isEnglish: Bool {
        switch language {
        case .system:
            let preferred = Locale.preferredLanguages.first ?? ""
            return !preferred.hasPrefix("zh")
        case .zhHans:
            return false
        case .en:
            return true
        }
    }

    /// 非 MainActor 环境或扩展插件快速获取当前是否为英文
    nonisolated public static var isCurrentEnglish: Bool {
        let saved = SharedStorageManager.shared.getString(forKey: SharedStorageManager.Keys.appLanguage)
            ?? UserDefaults.standard.string(forKey: SharedStorageManager.Keys.appLanguage)
            ?? AppLanguage.system.rawValue
        let lang = AppLanguage(rawValue: saved) ?? .system
        switch lang {
        case .system:
            let preferred = Locale.preferredLanguages.first ?? ""
            return !preferred.hasPrefix("zh")
        case .zhHans:
            return false
        case .en:
            return true
        }
    }
}

/// 快速本地化翻译工具
public enum L10n {
    /// 当前是否处于英文状态
    public static var isEnglish: Bool {
        AppLanguageManager.isCurrentEnglish
    }

    /// 双语对照翻译器：中文为基准，英文为对照
    @inline(__always)
    public static func tr(_ zh: String, _ en: String) -> String {
        isEnglish ? en : zh
    }
}
