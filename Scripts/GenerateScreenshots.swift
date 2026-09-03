import SwiftUI
import AppKit

@main
struct GenerateScreenshotsApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let width: CGFloat = 962
        let height: CGFloat = 764
        let coordinator = AppMenuStateCoordinator.shared

        // 1. Generate English Screenshots
        print("🌍 [Screenshots] Generating English screenshots in docs/screenshots/en/ ...")
        AppLanguageManager.shared.language = .en
        UserDefaults.standard.set("en", forKey: SharedStorageManager.Keys.appLanguage)
        _ = SharedStorageManager.shared.setString("en", forKey: SharedStorageManager.Keys.appLanguage)

        let enDir = URL(fileURLWithPath: "docs/screenshots/en")
        try? FileManager.default.createDirectory(at: enDir, withIntermediateDirectories: true)

        coordinator.canvasItems = StarterPreset.developer.canvasItems()

        save(render(MainWindowView(coordinator: coordinator, initialSection: .canvas), width: width, height: height), to: enDir.appendingPathComponent("settings-actions.png"))
        save(render(MainWindowView(coordinator: coordinator, initialSection: .customApps), width: width, height: height), to: enDir.appendingPathComponent("settings-advanced.png"))
        save(render(MainWindowView(coordinator: coordinator, initialSection: .settings), width: width, height: height, delaySeconds: 0.5), to: enDir.appendingPathComponent("settings-permissions.png"))
        save(render(MainWindowView(coordinator: coordinator, initialSection: .diagnostics), width: width, height: height), to: enDir.appendingPathComponent("settings-diagnostics.png"))
        save(render(MainWindowView(coordinator: coordinator, initialSection: .canvas), width: width, height: height, isDark: true), to: enDir.appendingPathComponent("settings-dark.png"))
        save(render(FinderContextMenuMockupView(isEnglish: true), width: 1100, height: 800), to: enDir.appendingPathComponent("finder-context-menu.png"))

        // 2. Generate Chinese Screenshots
        print("🇨🇳 [Screenshots] Generating Chinese screenshots in docs/screenshots/ ...")
        AppLanguageManager.shared.language = .zhHans
        UserDefaults.standard.set("zhHans", forKey: SharedStorageManager.Keys.appLanguage)
        _ = SharedStorageManager.shared.setString("zhHans", forKey: SharedStorageManager.Keys.appLanguage)

        let zhDir = URL(fileURLWithPath: "docs/screenshots")
        try? FileManager.default.createDirectory(at: zhDir, withIntermediateDirectories: true)

        coordinator.canvasItems = StarterPreset.developer.canvasItems()

        save(render(MainWindowView(coordinator: coordinator, initialSection: .canvas), width: width, height: height), to: zhDir.appendingPathComponent("settings-actions.png"))
        save(render(MainWindowView(coordinator: coordinator, initialSection: .customApps), width: width, height: height), to: zhDir.appendingPathComponent("settings-advanced.png"))
        save(render(MainWindowView(coordinator: coordinator, initialSection: .settings), width: width, height: height, delaySeconds: 0.5), to: zhDir.appendingPathComponent("settings-permissions.png"))
        save(render(MainWindowView(coordinator: coordinator, initialSection: .diagnostics), width: width, height: height), to: zhDir.appendingPathComponent("settings-diagnostics.png"))
        save(render(MainWindowView(coordinator: coordinator, initialSection: .canvas), width: width, height: height, isDark: true), to: zhDir.appendingPathComponent("settings-dark.png"))
        save(render(FinderContextMenuMockupView(isEnglish: false), width: 1100, height: 800), to: zhDir.appendingPathComponent("finder-context-menu.png"))

        print("✅ All English and Chinese screenshots generated successfully!")
    }

    @MainActor
    static func render<V: View>(_ view: V, width: CGFloat, height: CGFloat, isDark: Bool = false, delaySeconds: Double = 0.1) -> Data {
        let content = view
            .environment(\.colorScheme, isDark ? .dark : .light)
            .preferredColorScheme(isDark ? .dark : .light)

        let host = NSHostingView(rootView: AnyView(content))
        host.frame = NSRect(x: 0, y: 0, width: width, height: height)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        window.contentView = host
        window.layoutIfNeeded()
        host.layoutSubtreeIfNeeded()

        if delaySeconds > 0 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: delaySeconds))
            window.layoutIfNeeded()
            host.layoutSubtreeIfNeeded()
        }

        let scale: CGFloat = 2.0
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(width * scale),
            pixelsHigh: Int(height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        rep.size = NSSize(width: width, height: height)

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context
        host.displayIgnoringOpacity(host.bounds, in: context!)
        NSGraphicsContext.restoreGraphicsState()

        return rep.representation(using: .png, properties: [:])!
    }

    static func save(_ data: Data, to url: URL) {
        try? data.write(to: url)
    }
}

/// Simulated Finder Context Menu Mockup View
struct FinderContextMenuMockupView: View {
    var isEnglish: Bool = true

    var body: some View {
        ZStack {
            // macOS Desktop background wallpaper
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.28, blue: 0.48), Color(red: 0.05, green: 0.12, blue: 0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Finder Window Mockup
            VStack(spacing: 0) {
                // Window Header
                HStack(spacing: 8) {
                    Circle().fill(Color(red: 1.0, green: 0.38, blue: 0.36)).frame(width: 12, height: 12)
                    Circle().fill(Color(red: 1.0, green: 0.76, blue: 0.25)).frame(width: 12, height: 12)
                    Circle().fill(Color(red: 0.16, green: 0.80, blue: 0.30)).frame(width: 12, height: 12)
                    Spacer()
                    Text(isEnglish ? "Documents — EasyRight Demo" : "文稿 — EasyRight 演示")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(nsColor: .windowBackgroundColor))

                Divider()

                // File contents area
                HStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        Text(isEnglish ? "README.md" : "README_zh.md")
                            .font(.system(size: 12))
                    }
                    .padding(12)

                    VStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        Text("demo.txt")
                            .font(.system(size: 12))
                    }
                    .padding(12)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(8)

                    VStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.cyan)
                        Text(isEnglish ? "Projects" : "项目工程")
                            .font(.system(size: 12))
                    }
                    .padding(12)

                    Spacer()
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(nsColor: .controlBackgroundColor))
            }
            .frame(width: 800, height: 520)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)

            // Right-click Context Menu Overlay
            VStack(alignment: .leading, spacing: 2) {
                menuItem(isEnglish ? "Open" : "打开", shortcut: nil)
                menuItem(isEnglish ? "Open With" : "打开方式", shortcut: nil, hasSubmenu: true)
                menuDivider
                menuItem(isEnglish ? "Move to Trash" : "移到废纸篓", shortcut: "⌘⌫")
                menuDivider
                menuItem(isEnglish ? "Get Info" : "显示简介", shortcut: "⌘I")
                menuItem(isEnglish ? "Rename" : "重新命名", shortcut: nil)
                menuItem(isEnglish ? "Duplicate" : "复制", shortcut: "⌘D")
                menuItem(isEnglish ? "Make Alias" : "制作替身", shortcut: nil)
                menuItem(isEnglish ? "Quick Look \"demo.txt\"" : "快速查看 “demo.txt”", shortcut: "Space")
                menuDivider
                menuItem(isEnglish ? "Copy \"demo.txt\"" : "拷贝 “demo.txt”", shortcut: "⌘C")
                menuItem(isEnglish ? "Share…" : "共享…", shortcut: nil)
                menuDivider
                // EasyRight Actions
                menuItem(isEnglish ? "New Plain Text (.txt)" : "新建 文本文件 (.txt)", icon: "doc.text")
                menuItem(isEnglish ? "New Word Document (.docx)" : "新建 Word 文档 (.docx)", icon: "doc.richtext")
                menuItem(isEnglish ? "New Markdown Document (.md)" : "新建 Markdown 文档 (.md)", icon: "doc.text.fill")
                menuDivider
                menuItem(isEnglish ? "Cut" : "剪切", icon: "scissors", shortcut: "⌘X")
                menuItem(isEnglish ? "Copy Full Path" : "拷贝完整路径", icon: "link")
                menuItem(isEnglish ? "Copy File Name" : "拷贝文件名", icon: "pencil.and.outline")
                menuDivider
                menuItem(isEnglish ? "Open in Terminal" : "在 系统终端 中打开", icon: "terminal")
                menuItem(isEnglish ? "Open in VS Code" : "在 VS Code 中打开", icon: "chevron.left.forwardslash.chevron.right")
                menuDivider
                menuItem(isEnglish ? "Calculate SHA256 Checksum" : "获取文件 SHA256 校验码", icon: "number.square.fill")
                menuItem(isEnglish ? "Generate QR Code from Clipboard" : "从剪贴板生成二维码", icon: "qrcode")
                menuDivider
                menuItem(isEnglish ? "Services" : "服务", shortcut: nil, hasSubmenu: true)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
            .frame(width: isEnglish ? 270 : 280)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                    .shadow(color: .black.opacity(0.28), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
            .offset(x: 100, y: 30)
        }
        .frame(width: 1100, height: 800)
    }

    private func menuItem(_ title: String, icon: String? = nil, shortcut: String? = nil, hasSubmenu: Bool = false) -> some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .frame(width: 14)
            } else {
                Spacer().frame(width: 14)
            }

            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(Color.primary)

            Spacer()

            if let shortcut {
                Text(shortcut)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.secondary)
            }
            if hasSubmenu {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }

    private var menuDivider: some View {
        Divider()
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
    }
}
