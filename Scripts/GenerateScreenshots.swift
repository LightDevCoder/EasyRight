import SwiftUI
import AppKit

@main
struct GenerateScreenshotsApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        // Set English language
        AppLanguageManager.shared.language = .en
        UserDefaults.standard.set("en", forKey: SharedStorageManager.Keys.appLanguage)
        _ = SharedStorageManager.shared.setString("en", forKey: SharedStorageManager.Keys.appLanguage)

        let targetDir = URL(fileURLWithPath: "docs/screenshots/en")
        try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)

        let width: CGFloat = 962
        let height: CGFloat = 764

        let coordinator = AppMenuStateCoordinator.shared
        // Ensure default canvas items are populated
        if coordinator.canvasItems.isEmpty {
            coordinator.canvasItems = StarterPreset.developer.canvasItems()
        }

        print("📸 Rendering settings-actions.png (Action Canvas)...")
        let canvasView = MainWindowView(coordinator: coordinator, initialSection: .canvas)
        save(render(canvasView, width: width, height: height), to: targetDir.appendingPathComponent("settings-actions.png"))

        print("📸 Rendering settings-advanced.png (Custom Apps)...")
        let customAppsView = MainWindowView(coordinator: coordinator, initialSection: .customApps)
        save(render(customAppsView, width: width, height: height), to: targetDir.appendingPathComponent("settings-advanced.png"))

        print("📸 Rendering settings-permissions.png (General Settings)...")
        let settingsView = MainWindowView(coordinator: coordinator, initialSection: .settings)
        save(render(settingsView, width: width, height: height, delaySeconds: 0.5), to: targetDir.appendingPathComponent("settings-permissions.png"))

        print("📸 Rendering settings-diagnostics.png (Diagnostics)...")
        let diagnosticsView = MainWindowView(coordinator: coordinator, initialSection: .diagnostics)
        save(render(diagnosticsView, width: width, height: height), to: targetDir.appendingPathComponent("settings-diagnostics.png"))

        print("📸 Rendering settings-dark.png (Dark Mode)...")
        let darkView = MainWindowView(coordinator: coordinator, initialSection: .canvas)
        save(render(darkView, width: width, height: height, isDark: true), to: targetDir.appendingPathComponent("settings-dark.png"))

        print("📸 Rendering finder-context-menu.png...")
        let contextMenuView = FinderContextMenuMockupView()
        save(render(contextMenuView, width: 1100, height: 800), to: targetDir.appendingPathComponent("finder-context-menu.png"))

        print("✅ All 6 English screenshots generated successfully in docs/screenshots/en/")
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
        host.layoutSubtreeIfNeeded()

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

/// Simulated Finder Context Menu Mockup View in English
struct FinderContextMenuMockupView: View {
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
                    Text("Documents — EasyRight Demo")
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
                        Text("README.md")
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
                        Text("Projects")
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
                menuItem("Open", shortcut: nil)
                menuItem("Open With", shortcut: nil, hasSubmenu: true)
                menuDivider
                menuItem("Move to Trash", shortcut: "⌘⌫")
                menuDivider
                menuItem("Get Info", shortcut: "⌘I")
                menuItem("Rename", shortcut: nil)
                menuItem("Duplicate", shortcut: "⌘D")
                menuItem("Make Alias", shortcut: nil)
                menuItem("Quick Look \"demo.txt\"", shortcut: "Space")
                menuDivider
                menuItem("Copy \"demo.txt\"", shortcut: "⌘C")
                menuItem("Share…", shortcut: nil)
                menuDivider
                // EasyRight Actions
                menuItem("New Plain Text (.txt)", icon: "doc.text")
                menuItem("New Word Document (.docx)", icon: "doc.richtext")
                menuItem("New Markdown Document (.md)", icon: "doc.text.fill")
                menuDivider
                menuItem("Cut", icon: "scissors", shortcut: "⌘X")
                menuItem("Copy Full Path", icon: "link")
                menuItem("Copy File Name", icon: "pencil.and.outline")
                menuDivider
                menuItem("Open in Terminal", icon: "terminal")
                menuItem("Open in VS Code", icon: "chevron.left.forwardslash.chevron.right")
                menuDivider
                menuItem("Calculate SHA256 Checksum", icon: "number.square.fill")
                menuItem("Generate QR Code from Clipboard", icon: "qrcode")
                menuDivider
                menuItem("Services", shortcut: nil, hasSubmenu: true)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
            .frame(width: 270)
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
