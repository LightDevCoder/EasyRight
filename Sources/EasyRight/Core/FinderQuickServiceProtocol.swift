import Foundation

/// 动态服务 helper 与 Host 之间的最小稳定协议。
public enum FinderQuickServiceProtocol {
    public static let bundleIdentifier = "com.easyright.app.quickservice"
    public static let bundleDirectoryName = "EasyRightQuickActions.service"
    public static let executableName = "EasyRightQuickService"
    public static let providerPortName = "EasyRightQuickActions"
    public static let forwardedActionPasteboardType = "com.easyright.app.direct-action-id"
    public static let hostPaletteMenuTitle = "EasyRight…"
}
